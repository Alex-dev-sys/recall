"""
AI Pipeline for Task Extraction and Analysis
Supports multiple AI providers (OpenAI, Anthropic, Together AI, etc.)
"""

import json
import asyncio
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Optional, Any
from loguru import logger

try:
    from openai import AsyncOpenAI
except ImportError:
    AsyncOpenAI = None

try:
    from anthropic import AsyncAnthropic
except ImportError:
    AsyncAnthropic = None

try:
    from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
    TENACITY_AVAILABLE = True
except ImportError:
    TENACITY_AVAILABLE = False

from prompts import (
    EXTRACTOR_SYSTEM_PROMPT,
    EXTRACTOR_USER_TEMPLATE,
    DEADLINE_PARSER_SYSTEM_PROMPT,
    DEADLINE_PARSER_USER_TEMPLATE,
    PRIORITIZER_SYSTEM_PROMPT,
    PRIORITIZER_USER_TEMPLATE,
    DEDUPLICATOR_SYSTEM_PROMPT,
    DEDUPLICATOR_USER_TEMPLATE,
    get_current_date,
    format_existing_tasks,
)


class AIProvider:
    """Base class for AI providers"""

    async def chat_completion(
        self, system_prompt: str, user_prompt: str, temperature: float = 0.7
    ) -> str:
        raise NotImplementedError


class OpenAIProvider(AIProvider):
    """OpenAI API provider with retry logic"""

    def __init__(self, api_key: str, model: str = "gpt-4o-mini", base_url: Optional[str] = None):
        if AsyncOpenAI is None:
            raise ImportError("openai package not installed")
        self.client = AsyncOpenAI(api_key=api_key, base_url=base_url)
        self.model = model

    async def _make_request(self, system_prompt: str, user_prompt: str, temperature: float) -> str:
        """Make API request (can be retried)"""
        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=temperature,
            max_tokens=2000,
        )
        return response.choices[0].message.content.strip()

    async def chat_completion(
        self, system_prompt: str, user_prompt: str, temperature: float = 0.7
    ) -> str:
        max_retries = 3
        last_error = None
        
        for attempt in range(max_retries):
            try:
                return await self._make_request(system_prompt, user_prompt, temperature)
            except Exception as e:
                last_error = e
                if attempt < max_retries - 1:
                    wait_time = (2 ** attempt)  # Exponential backoff: 1, 2, 4 seconds
                    logger.warning(f"OpenAI API error (attempt {attempt + 1}/{max_retries}): {e}. Retrying in {wait_time}s...")
                    await asyncio.sleep(wait_time)
                else:
                    logger.error(f"OpenAI API error after {max_retries} attempts: {e}")
        
        raise last_error


class AnthropicProvider(AIProvider):
    """Anthropic Claude API provider with retry logic"""

    def __init__(self, api_key: str, model: str = "claude-3-5-sonnet-20241022"):
        if AsyncAnthropic is None:
            raise ImportError("anthropic package not installed")
        self.client = AsyncAnthropic(api_key=api_key)
        self.model = model

    async def chat_completion(
        self, system_prompt: str, user_prompt: str, temperature: float = 0.7
    ) -> str:
        max_retries = 3
        last_error = None
        
        for attempt in range(max_retries):
            try:
                response = await self.client.messages.create(
                    model=self.model,
                    max_tokens=2000,
                    temperature=temperature,
                    system=system_prompt,
                    messages=[{"role": "user", "content": user_prompt}],
                )
                return response.content[0].text.strip()
            except Exception as e:
                last_error = e
                if attempt < max_retries - 1:
                    wait_time = (2 ** attempt)
                    logger.warning(f"Anthropic API error (attempt {attempt + 1}/{max_retries}): {e}. Retrying in {wait_time}s...")
                    await asyncio.sleep(wait_time)
                else:
                    logger.error(f"Anthropic API error after {max_retries} attempts: {e}")
        
        raise last_error


class AIPipeline:
    """
    Main AI Pipeline for task extraction and analysis.
    Implements Chain of Thought processing through multiple AI calls.
    """

    def __init__(
        self,
        provider: AIProvider,
        min_confidence: float = 0.6,
        duplicate_threshold: float = 0.85,
    ):
        self.provider = provider
        self.min_confidence = min_confidence
        self.duplicate_threshold = duplicate_threshold

    async def extract_tasks(
        self, message_text: str, chat_title: str, sender_name: str
    ) -> List[Dict[str, Any]]:
        """
        Step 1: Extract tasks from message text.

        Returns:
            List of extracted tasks with metadata
        """
        logger.info(f"Extracting tasks from message in chat '{chat_title}'")

        user_prompt = EXTRACTOR_USER_TEMPLATE.format(
            chat_title=chat_title, sender_name=sender_name, message_text=message_text
        )

        try:
            response = await self.provider.chat_completion(
                system_prompt=EXTRACTOR_SYSTEM_PROMPT,
                user_prompt=user_prompt,
                temperature=0.3,  # Lower temperature for more consistent extraction
            )

            # Parse JSON response
            tasks = self._parse_json_response(response)
            
            # Ensure we have a list
            if not isinstance(tasks, list):
                logger.warning(f"Expected list but got {type(tasks).__name__}, wrapping in list")
                tasks = [tasks] if tasks else []

            # Filter by confidence
            filtered_tasks = [
                task for task in tasks if task.get("confidence", 0) >= self.min_confidence
            ]

            logger.info(
                f"Extracted {len(filtered_tasks)} tasks (filtered from {len(tasks)} by confidence)"
            )
            return filtered_tasks

        except Exception as e:
            logger.error(f"Task extraction failed: {e}")
            return []

    async def parse_deadline(self, deadline_hint: Optional[str]) -> Dict[str, Any]:
        """
        Step 2: Parse deadline from natural language hint.

        Args:
            deadline_hint: Natural language time reference (e.g., "завтра вечером")

        Returns:
            Dict with parsed_datetime (ISO string or None), is_precise (bool), reasoning
        """
        if not deadline_hint:
            return {
                "parsed_datetime": None,
                "is_precise": False,
                "reasoning": "No deadline specified",
            }

        logger.debug(f"Parsing deadline: {deadline_hint}")

        current_date = get_current_date()
        system_prompt = DEADLINE_PARSER_SYSTEM_PROMPT.format(current_date=current_date)
        user_prompt = DEADLINE_PARSER_USER_TEMPLATE.format(deadline_hint=deadline_hint)

        try:
            response = await self.provider.chat_completion(
                system_prompt=system_prompt, user_prompt=user_prompt, temperature=0.1
            )

            result = self._parse_json_response(response)
            logger.debug(f"Parsed deadline: {result}")
            return result

        except Exception as e:
            logger.error(f"Deadline parsing failed: {e}")
            return {
                "parsed_datetime": None,
                "is_precise": False,
                "reasoning": f"Parsing error: {str(e)}",
            }

    async def prioritize_task(
        self,
        task_text: str,
        deadline: Optional[str],
        original_quote: str,
    ) -> Dict[str, Any]:
        """
        Step 3: Determine task priority.

        Args:
            task_text: Task description
            deadline: ISO datetime string or None
            original_quote: Original text from message

        Returns:
            Dict with priority (urgent/high/medium/low) and reasoning
        """
        logger.debug(f"Prioritizing task: {task_text}")

        current_time = datetime.now(timezone.utc).isoformat()
        user_prompt = PRIORITIZER_USER_TEMPLATE.format(
            task_text=task_text,
            deadline=deadline or "не указан",
            current_time=current_time,
            original_quote=original_quote,
        )

        try:
            response = await self.provider.chat_completion(
                system_prompt=PRIORITIZER_SYSTEM_PROMPT,
                user_prompt=user_prompt,
                temperature=0.2,
            )

            result = self._parse_json_response(response)
            logger.debug(f"Priority: {result['priority']} - {result['reasoning']}")
            return result

        except Exception as e:
            logger.error(f"Prioritization failed: {e}")
            return {"priority": "medium", "reasoning": f"Default priority due to error: {e}"}

    async def check_duplicate(
        self, new_task: str, existing_tasks: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Step 4: Check if task is a duplicate of existing tasks.

        Args:
            new_task: New task text
            existing_tasks: List of active tasks to compare against

        Returns:
            Dict with is_duplicate (bool), duplicate_of_id (str or None), similarity_score, reasoning
        """
        if not existing_tasks:
            return {
                "is_duplicate": False,
                "duplicate_of_id": None,
                "similarity_score": 0.0,
                "reasoning": "No existing tasks to compare",
            }

        logger.debug(f"Checking for duplicates: {new_task}")

        formatted_tasks = format_existing_tasks(existing_tasks)
        user_prompt = DEDUPLICATOR_USER_TEMPLATE.format(
            new_task=new_task, existing_tasks=formatted_tasks
        )

        try:
            response = await self.provider.chat_completion(
                system_prompt=DEDUPLICATOR_SYSTEM_PROMPT,
                user_prompt=user_prompt,
                temperature=0.1,
            )

            result = self._parse_json_response(response)

            # Apply threshold
            if result.get("similarity_score", 0) < self.duplicate_threshold:
                result["is_duplicate"] = False
                result["duplicate_of_id"] = None

            logger.debug(
                f"Duplicate check: {result['is_duplicate']} (score: {result['similarity_score']})"
            )
            return result

        except Exception as e:
            logger.error(f"Duplicate check failed: {e}")
            return {
                "is_duplicate": False,
                "duplicate_of_id": None,
                "similarity_score": 0.0,
                "reasoning": f"Check failed: {e}",
            }

    async def process_message(
        self,
        message_text: str,
        chat_title: str,
        sender_name: str,
        chat_id: int,
        message_id: int,
        existing_tasks: List[Dict[str, Any]],
    ) -> List[Dict[str, Any]]:
        """
        Full pipeline: Extract -> Check Duplicates -> Parse Deadline -> Prioritize.

        Args:
            message_text: Message content
            chat_title: Chat name
            sender_name: Sender name
            chat_id: Telegram chat ID
            message_id: Telegram message ID
            existing_tasks: Active tasks for duplicate checking

        Returns:
            List of processed tasks ready to save to database
        """
        logger.info(f"Processing message from {sender_name} in {chat_title}")

        # Step 1: Extract tasks
        extracted_tasks = await self.extract_tasks(message_text, chat_title, sender_name)

        if not extracted_tasks:
            logger.info("No tasks extracted")
            return []

        processed_tasks = []

        for task in extracted_tasks:
            try:
                # Step 2: Check for duplicates
                duplicate_result = await self.check_duplicate(
                    task["task_text"], existing_tasks
                )

                if duplicate_result["is_duplicate"]:
                    logger.info(
                        f"Task '{task['task_text']}' is a duplicate, skipping"
                    )
                    continue

                # Step 3: Parse deadline
                deadline_result = await self.parse_deadline(task.get("deadline_hint"))

                # Step 4: Prioritize
                priority_result = await self.prioritize_task(
                    task["task_text"],
                    deadline_result["parsed_datetime"],
                    task["original_quote"],
                )

                # Construct source link (only works for supergroups/channels with -100 prefix)
                chat_id_str = str(chat_id)
                if chat_id_str.startswith("-100"):
                    # Supergroup or channel - remove -100 prefix for link
                    source_link = f"https://t.me/c/{chat_id_str[4:]}/{message_id}"
                elif chat_id < 0:
                    # Regular group (starts with -)
                    source_link = None  # No direct link available
                else:
                    # Private chat - no shareable link
                    source_link = None

                # Build final task object
                processed_task = {
                    "content": task["task_text"],
                    "original_quote": task["original_quote"],
                    "task_type": task["task_type"],
                    "priority": priority_result["priority"],
                    "deadline": deadline_result["parsed_datetime"],
                    "deadline_is_precise": deadline_result["is_precise"],
                    "status": "new",
                    "source_link": source_link,
                    "confidence": task["confidence"],
                    "is_duplicate": False,
                    "duplicate_of": None,
                    "chat_id": chat_id,
                    "message_id": message_id,
                    "ai_reasoning": {
                        "extraction": {
                            "confidence": task["confidence"],
                            "task_type": task["task_type"],
                        },
                        "deadline": deadline_result,
                        "priority": priority_result,
                        "duplicate_check": duplicate_result,
                    },
                }

                processed_tasks.append(processed_task)
                logger.info(
                    f"Processed task: '{task['task_text']}' [Priority: {priority_result['priority']}]"
                )

            except Exception as e:
                logger.error(f"Failed to process task '{task.get('task_text')}': {e}")
                continue

        logger.info(f"Successfully processed {len(processed_tasks)} tasks")
        return processed_tasks

    def _parse_json_response(self, response: str) -> Any:
        """
        Parse JSON from AI response, handling markdown code blocks.

        Args:
            response: Raw AI response text

        Returns:
            Parsed JSON object

        Raises:
            ValueError: If JSON parsing fails
        """
        # Remove markdown code blocks if present
        response = response.strip()

        if response.startswith("```json"):
            response = response[7:]
        elif response.startswith("```"):
            response = response[3:]

        if response.endswith("```"):
            response = response[:-3]

        response = response.strip()

        try:
            parsed = json.loads(response)
            # Handle case where AI returns {"tasks": [...]} instead of [...]
            if isinstance(parsed, dict) and "tasks" in parsed:
                return parsed["tasks"]
            return parsed
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON: {e}\nResponse: {response}")
            raise ValueError(f"Invalid JSON response: {e}")


def create_ai_provider(config: Dict[str, Any]) -> AIProvider:
    """
    Factory function to create AI provider based on config.

    Args:
        config: AI configuration dict with keys: provider, model, api_key, base_url

    Returns:
        AIProvider instance

    Raises:
        ValueError: If provider is not supported
    """
    provider_type = config.get("provider", "openai").lower()
    api_key = config["api_key"]
    model = config.get("model", "gpt-4o-mini")
    base_url = config.get("base_url")

    if provider_type == "openai":
        return OpenAIProvider(api_key=api_key, model=model, base_url=base_url)
    elif provider_type == "anthropic":
        return AnthropicProvider(api_key=api_key, model=model)
    else:
        raise ValueError(f"Unsupported AI provider: {provider_type}")


# Example usage
if __name__ == "__main__":
    import asyncio

    async def test_pipeline():
        # Example configuration
        config = {
            "provider": "openai",
            "model": "gpt-4o-mini",
            "api_key": "your-api-key-here",
        }

        provider = create_ai_provider(config)
        pipeline = AIPipeline(provider)

        # Test message
        message = "Привет! Можешь завтра до обеда отправить мне отчет? Это срочно!"

        tasks = await pipeline.process_message(
            message_text=message,
            chat_title="Рабочий чат",
            sender_name="Иван",
            chat_id=123456789,
            message_id=42,
            existing_tasks=[],
        )

        print(json.dumps(tasks, indent=2, ensure_ascii=False))

    asyncio.run(test_pipeline())
