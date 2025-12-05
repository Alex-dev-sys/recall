#!/usr/bin/env python3
"""
Test GPT Lama API connection and AI extraction.
"""

import asyncio
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

import yaml
from openai import AsyncOpenAI


def load_config():
    """Load configuration from config.yaml"""
    config_path = Path(__file__).parent / "config" / "config.yaml"

    if not config_path.exists():
        print("❌ Config file not found: config/config.yaml")
        sys.exit(1)

    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


async def test_gptlama():
    """Test GPT Lama API"""

    print("\n" + "=" * 60)
    print("GPT LAMA API - CONNECTION TEST")
    print("=" * 60 + "\n")

    # Load config
    config = load_config()
    ai_config = config["ai"]

    print(f"📡 Connecting to GPT Lama API...")
    print(f"   Base URL: {ai_config['base_url']}")
    print(f"   Model: {ai_config['model']}\n")

    # Create client
    client = AsyncOpenAI(
        api_key=ai_config["api_key"],
        base_url=ai_config["base_url"],
    )

    # Test 1: Simple completion
    print("🧪 Test 1: Simple completion...")
    try:
        response = await client.chat.completions.create(
            model=ai_config["model"],
            messages=[
                {"role": "system", "content": "Ты - полезный ассистент."},
                {"role": "user", "content": "Скажи 'привет' по-русски одним словом."}
            ],
            max_tokens=50,
            temperature=0.7,
        )

        result = response.choices[0].message.content
        print(f"   ✅ Response: {result}\n")

    except Exception as e:
        print(f"   ❌ Failed: {e}\n")
        return False

    # Test 2: Task extraction (как в реальном Pipeline)
    print("🧪 Test 2: Task extraction from message...")

    test_message = "Привет! Можешь завтра до обеда отправить мне отчет? Это срочно!"

    extraction_prompt = """Ты — интеллектуальный ассистент для извлечения задач из текстовых сообщений.

Найди все задачи, просьбы и обещания в тексте.

ФОРМАТ ОТВЕТА: Отвечай ТОЛЬКО валидным JSON массивом.

Формат:
{
  "task_text": "краткая суть задачи",
  "original_quote": "точная цитата",
  "task_type": "request|promise|agreement|reminder",
  "deadline_hint": "упоминание времени или null",
  "confidence": float от 0 до 1
}

Если задач нет, верни пустой массив []."""

    try:
        response = await client.chat.completions.create(
            model=ai_config["model"],
            messages=[
                {"role": "system", "content": extraction_prompt},
                {"role": "user", "content": f"Сообщение:\n{test_message}\n\nИзвлеки задачи в JSON формате."}
            ],
            max_tokens=500,
            temperature=0.3,
        )

        result = response.choices[0].message.content
        print(f"   ✅ AI Response:")
        print(f"   {result}\n")

        # Try to parse JSON
        import json

        # Remove markdown code blocks if present
        if result.startswith("```"):
            result = result.split("```")[1]
            if result.startswith("json"):
                result = result[4:]
        result = result.strip()

        tasks = json.loads(result)

        if isinstance(tasks, list) and len(tasks) > 0:
            print(f"   ✅ Extracted {len(tasks)} task(s):")
            for i, task in enumerate(tasks, 1):
                print(f"      {i}. {task.get('task_text', 'N/A')}")
                print(f"         Type: {task.get('task_type', 'N/A')}")
                print(f"         Confidence: {task.get('confidence', 0)}")
        else:
            print("   ⚠️  No tasks extracted")

        print()

    except json.JSONDecodeError as e:
        print(f"   ⚠️  JSON parsing failed: {e}")
        print(f"   Raw response: {result}\n")
    except Exception as e:
        print(f"   ❌ Failed: {e}\n")
        return False

    # Test 3: Check available models
    print("🧪 Test 3: Checking available models...")
    try:
        models = await client.models.list()
        print(f"   ✅ Available models:")
        for model in models.data[:5]:  # Show first 5
            print(f"      - {model.id}")
        print()
    except Exception as e:
        print(f"   ⚠️  Could not list models: {e}\n")

    # Summary
    print("=" * 60)
    print("✅ GPT LAMA API TEST PASSED")
    print("=" * 60)
    print("\n🎉 AI API работает корректно!")
    print("\nМодель используется: " + ai_config['model'])
    print("\n💡 Теперь можно запускать Worker:")
    print("   python src/worker.py")
    print()

    return True


if __name__ == "__main__":
    try:
        success = asyncio.run(test_gptlama())
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Test interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
