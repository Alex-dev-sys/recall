"""
Main Worker Process for Recall Project.
Listens to Telegram messages and extracts tasks using AI Pipeline.
"""

import asyncio
import signal
import sys
from typing import Dict, Set
from datetime import datetime
from loguru import logger
from pyrogram import Client, filters
from pyrogram.types import Message
from pyrogram.handlers import MessageHandler

from database import DatabaseManager
from session_manager import SessionManager
from ai_pipeline import AIPipeline, create_ai_provider


class RecallWorker:
    """
    Main worker that manages user sessions and processes messages.
    """

    def __init__(self, config: Dict):
        """
        Args:
            config: Configuration dict with all settings
        """
        self.config = config
        self.is_running = False
        self.shutdown_event = asyncio.Event()

        # Initialize components
        self.db = DatabaseManager(
            supabase_url=config["supabase"]["url"],
            supabase_key=config["supabase"]["service_role_key"],
        )

        self.session_manager = SessionManager(
            api_id=config["telegram"]["api_id"],
            api_hash=config["telegram"]["api_hash"],
            encryption_key=config["telegram"]["session_encryption_key"],
        )

        ai_provider = create_ai_provider(config["ai"])
        self.ai_pipeline = AIPipeline(
            provider=ai_provider,
            min_confidence=config["pipeline"]["min_confidence_threshold"],
            duplicate_threshold=config["pipeline"]["duplicate_similarity_threshold"],
        )

        # Track monitored chats for each user: {user_id: {chat_id, ...}}
        self.monitored_chats: Dict[str, Set[int]] = {}

        # Worker session IDs: {user_id: session_id}
        self.worker_sessions: Dict[str, str] = {}

        logger.info("RecallWorker initialized")

    async def start(self):
        """Start the worker and load all user sessions"""
        self.is_running = True
        logger.info("Starting RecallWorker...")

        try:
            # Load all active user profiles
            profiles = await self.db.get_all_active_profiles()
            logger.info(f"Found {len(profiles)} active profiles")

            # Start sessions for each user
            for profile in profiles:
                try:
                    await self._start_user_session(profile)
                except Exception as e:
                    logger.error(f"Failed to start session for user {profile['id']}: {e}")

            # Start background tasks
            asyncio.create_task(self._heartbeat_loop())
            asyncio.create_task(self._reminder_loop())

            logger.info("RecallWorker started successfully")

            # Wait for shutdown signal
            await self.shutdown_event.wait()

        except Exception as e:
            logger.error(f"Worker error: {e}")
        finally:
            await self.stop()

    async def _start_user_session(self, profile: Dict):
        """Start Pyrogram session for a user"""
        user_id = profile["id"]

        try:
            # Register worker session in DB
            worker_instance_id = f"worker_{user_id}_{datetime.now().timestamp()}"
            session_id = await self.db.register_worker_session(
                user_id=user_id, worker_instance_id=worker_instance_id
            )
            self.worker_sessions[user_id] = session_id

            # Load Pyrogram client
            client = await self.session_manager.load_client(
                user_id=user_id, encrypted_session=profile["encrypted_session"]
            )

            # Load monitored chats
            monitored_chats = await self.db.get_monitored_chats(user_id)
            self.monitored_chats[user_id] = {chat["chat_id"] for chat in monitored_chats}

            logger.info(
                f"User {user_id} session started. Monitoring {len(self.monitored_chats[user_id])} chats"
            )

            # Register message handler - FIX: use default arg to capture user_id correctly
            message_filter = filters.text & ~filters.me  # Text messages, not from self
            client.add_handler(
                MessageHandler(
                    lambda c, m, uid=user_id: self._handle_message(c, m, uid), 
                    message_filter
                )
            )

            # Update worker status
            await self.db.update_worker_status(session_id, "running")

        except Exception as e:
            logger.error(f"Failed to start user session {user_id}: {e}")
            if user_id in self.worker_sessions:
                await self.db.update_worker_status(
                    self.worker_sessions[user_id], "error", str(e)
                )
            raise

    async def cleanup_user(self, user_id: str):
        """
        Cleanup user data from memory to prevent memory leaks.
        Call this when user logs out or is deactivated.
        """
        # Remove from monitored chats cache
        self.monitored_chats.pop(user_id, None)
        
        # Remove from worker sessions
        session_id = self.worker_sessions.pop(user_id, None)
        if session_id:
            try:
                await self.db.update_worker_status(session_id, "stopped")
            except Exception as e:
                logger.error(f"Failed to update session status during cleanup: {e}")
        
        # Unload Pyrogram client
        await self.session_manager.unload_client(user_id)
        
        logger.info(f"Cleaned up user {user_id} from memory")

    async def _handle_message(self, client: Client, message: Message, user_id: str):
        """
        Message handler for incoming Telegram messages.

        Args:
            client: Pyrogram client
            message: Incoming message
            user_id: User ID who owns this session
        """
        try:
            chat_id = message.chat.id

            # Check if this chat is monitored
            if user_id not in self.monitored_chats:
                return

            if chat_id not in self.monitored_chats[user_id]:
                return

            # Skip empty messages
            if not message.text or len(message.text.strip()) < 3:
                return

            logger.info(
                f"Processing message from {message.from_user.first_name if message.from_user else 'Unknown'} "
                f"in chat {message.chat.title or chat_id}"
            )

            # Update last message time
            await self.db.update_chat_last_message(user_id, chat_id)

            # Get existing tasks for duplicate detection
            existing_tasks = await self.db.get_tasks_for_dedup(
                user_id=user_id,
                chat_id=chat_id,
                hours_back=self.config["pipeline"].get("dedup_hours_back", 72),
                limit=self.config["pipeline"]["max_tasks_for_dedup_check"],
            )

            # Process message through AI pipeline
            processed_tasks = await self.ai_pipeline.process_message(
                message_text=message.text,
                chat_title=message.chat.title or str(chat_id),
                sender_name=message.from_user.first_name
                if message.from_user
                else "Unknown",
                chat_id=chat_id,
                message_id=message.id,
                existing_tasks=existing_tasks,
            )

            # Save tasks to database
            for task_data in processed_tasks:
                task_data["user_id"] = user_id
                created_task = await self.db.create_task(task_data)

                logger.info(
                    f"Task created: {created_task['content']} "
                    f"[Priority: {created_task['priority']}, ID: {created_task['id']}]"
                )

                # Note: Push notification will be sent by Supabase Edge Function
                # via Database Webhook on INSERT

        except Exception as e:
            logger.error(f"Error handling message: {e}")

    async def _heartbeat_loop(self):
        """Send periodic heartbeats to database"""
        interval = self.config["worker"]["heartbeat_interval"]

        while self.is_running:
            try:
                await asyncio.sleep(interval)

                for user_id, session_id in self.worker_sessions.items():
                    try:
                        await self.db.heartbeat(session_id)
                    except Exception as e:
                        logger.error(f"Heartbeat failed for user {user_id}: {e}")

            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Heartbeat loop error: {e}")

    async def _reminder_loop(self):
        """Check for tasks that need reminder notifications"""
        if not self.config["notifications"]["enable_reminders"]:
            logger.info("Reminder notifications disabled")
            return

        # Run every 5 minutes
        interval = 300

        while self.is_running:
            try:
                await asyncio.sleep(interval)

                # Get tasks needing reminders
                tasks = await self.db.get_tasks_needing_reminders()

                for task in tasks:
                    try:
                        # Check if reminder already sent
                        already_sent = await self.db.has_notification_been_sent(
                            task["id"], "reminder"
                        )

                        if not already_sent:
                            logger.info(f"Task {task['id']} needs reminder notification")
                            # Log notification to DB to trigger Edge Function webhook
                            await self.db.log_notification(
                                task_id=task["id"],
                                notification_type="reminder",
                                success=True,  # Will be updated by Edge Function
                            )

                    except Exception as e:
                        logger.error(f"Error checking reminder for task {task['id']}: {e}")

            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Reminder loop error: {e}")

    async def add_monitored_chat(
        self, user_id: str, chat_id: int, chat_title: str, chat_type: str = "private"
    ):
        """Add a chat to monitoring list for a user"""
        try:
            # Add to database
            await self.db.add_monitored_chat(user_id, chat_id, chat_title, chat_type)

            # Update local cache
            if user_id not in self.monitored_chats:
                self.monitored_chats[user_id] = set()

            self.monitored_chats[user_id].add(chat_id)

            logger.info(f"Added monitored chat {chat_title} for user {user_id}")

        except Exception as e:
            logger.error(f"Failed to add monitored chat: {e}")
            raise

    async def remove_monitored_chat(self, user_id: str, chat_id: int):
        """Remove a chat from monitoring list"""
        try:
            # Remove from database
            await self.db.remove_monitored_chat(user_id, chat_id)

            # Update local cache
            if user_id in self.monitored_chats:
                self.monitored_chats[user_id].discard(chat_id)

            logger.info(f"Removed monitored chat {chat_id} for user {user_id}")

        except Exception as e:
            logger.error(f"Failed to remove monitored chat: {e}")
            raise

    async def stop(self):
        """Gracefully stop the worker"""
        if not self.is_running:
            return

        self.is_running = False
        logger.info("Stopping RecallWorker...")

        try:
            # Update all worker sessions to stopped
            for user_id, session_id in self.worker_sessions.items():
                try:
                    await self.db.update_worker_status(session_id, "stopping")
                except Exception as e:
                    logger.error(f"Failed to update status for {user_id}: {e}")

            # Stop all Pyrogram clients
            await self.session_manager.shutdown_all()

            # Final status update
            for user_id, session_id in self.worker_sessions.items():
                try:
                    await self.db.update_worker_status(session_id, "stopped")
                except Exception as e:
                    logger.error(f"Failed to finalize status for {user_id}: {e}")

            logger.info("RecallWorker stopped successfully")

        except Exception as e:
            logger.error(f"Error during shutdown: {e}")

    def trigger_shutdown(self):
        """Trigger graceful shutdown"""
        logger.info("Shutdown signal received")
        self.shutdown_event.set()


def setup_logging(config: Dict):
    """Setup logging configuration"""
    logger.remove()  # Remove default handler

    log_level = config["worker"]["log_level"]

    # Console handler
    logger.add(
        sys.stderr,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan> - <level>{message}</level>",
        level=log_level,
        colorize=True,
    )

    # File handler
    logger.add(
        config["logging"]["file"],
        rotation=f"{config['logging']['max_size_mb']} MB",
        retention=config["logging"]["backup_count"],
        format=config["logging"]["format"],
        level=log_level,
        encoding="utf-8",
    )

    logger.info("Logging configured")


def load_config() -> Dict:
    """Load configuration from YAML file"""
    import yaml
    from pathlib import Path

    config_path = Path(__file__).parent.parent / "config" / "config.yaml"

    if not config_path.exists():
        logger.error(f"Config file not found: {config_path}")
        sys.exit(1)

    with open(config_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    logger.info("Configuration loaded")
    return config


async def main():
    """Main entry point"""
    # Load config
    config = load_config()

    # Setup logging
    setup_logging(config)

    # Create worker
    worker = RecallWorker(config)

    # Setup signal handlers
    def signal_handler(sig, frame):
        worker.trigger_shutdown()

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Start worker
    try:
        await worker.start()
    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    # Use uvloop for better performance on Linux
    try:
        import uvloop

        asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())
        logger.info("Using uvloop for better performance")
    except ImportError:
        logger.info("uvloop not available, using default event loop")

    asyncio.run(main())
