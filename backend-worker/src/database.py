"""
Database Manager for Supabase operations.
Handles all database interactions for the Recall project.
Properly uses ThreadPoolExecutor to avoid blocking the event loop.
"""

import asyncio
from concurrent.futures import ThreadPoolExecutor
from functools import partial
from typing import Dict, List, Optional, Any, Callable, TypeVar
from datetime import datetime, timedelta, timezone
from loguru import logger
from supabase import create_client, Client as SupabaseClient


T = TypeVar('T')


class DatabaseManager:
    """
    Manages all database operations with Supabase.
    Uses ThreadPoolExecutor to run sync Supabase calls without blocking event loop.
    """

    def __init__(self, supabase_url: str, supabase_key: str, max_workers: int = 10):
        """
        Args:
            supabase_url: Supabase project URL
            supabase_key: Supabase service role key (for backend)
            max_workers: Maximum number of threads for database operations
        """
        self.client: SupabaseClient = create_client(supabase_url, supabase_key)
        self._executor = ThreadPoolExecutor(max_workers=max_workers)
        logger.info("Database connection initialized with thread pool")

    async def _run_sync(self, func: Callable[..., T], *args, **kwargs) -> T:
        """Run a synchronous function in thread pool executor"""
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(
            self._executor,
            partial(func, *args, **kwargs)
        )

    def shutdown(self):
        """Cleanup executor on shutdown"""
        self._executor.shutdown(wait=True)

    # ==========================================
    # PROFILES
    # ==========================================

    def _get_profile_sync(self, user_id: str):
        return (
            self.client.table("profiles")
            .select("*")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )

    async def get_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user profile by auth user ID"""
        try:
            response = await self._run_sync(self._get_profile_sync, user_id)
            return response.data
        except Exception as e:
            logger.error(f"Failed to get profile {user_id}: {e}")
            return None

    def _get_profile_by_telegram_id_sync(self, telegram_user_id: int):
        return (
            self.client.table("profiles")
            .select("*")
            .eq("telegram_user_id", telegram_user_id)
            .maybe_single()
            .execute()
        )

    async def get_profile_by_telegram_id(self, telegram_user_id: int) -> Optional[Dict[str, Any]]:
        """Get user profile by Telegram user ID"""
        try:
            response = await self._run_sync(self._get_profile_by_telegram_id_sync, telegram_user_id)
            return response.data
        except Exception as e:
            logger.error(f"Failed to get profile by telegram_id {telegram_user_id}: {e}")
            return None

    def _upsert_profile_sync(self, profile_data: Dict[str, Any]):
        return (
            self.client.table("profiles")
            .upsert(profile_data, on_conflict="id")
            .execute()
        )

    async def create_or_update_profile(
        self,
        user_id: str,
        telegram_user_id: int,
        encrypted_session: str,
        phone_number: str,
        first_name: Optional[str] = None,
        last_name: Optional[str] = None,
        username: Optional[str] = None,
        fcm_token: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Create or update user profile"""
        try:
            profile_data = {
                "id": user_id,
                "telegram_user_id": telegram_user_id,
                "encrypted_session": encrypted_session,
                "phone_number": phone_number,
                "first_name": first_name,
                "last_name": last_name,
                "username": username,
                "fcm_token": fcm_token,
                "is_active": True,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            }
            response = await self._run_sync(self._upsert_profile_sync, profile_data)
            logger.info(f"Profile upserted for user {user_id}")
            return response.data[0] if response.data else {}
        except Exception as e:
            logger.error(f"Failed to upsert profile: {e}")
            raise

    def _update_fcm_token_sync(self, user_id: str, fcm_token: str):
        return (
            self.client.table("profiles")
            .update({"fcm_token": fcm_token})
            .eq("id", user_id)
            .execute()
        )

    async def update_fcm_token(self, user_id: str, fcm_token: str):
        """Update FCM token for push notifications"""
        try:
            await self._run_sync(self._update_fcm_token_sync, user_id, fcm_token)
            logger.info(f"FCM token updated for user {user_id}")
        except Exception as e:
            logger.error(f"Failed to update FCM token: {e}")
            raise

    def _get_all_active_profiles_sync(self):
        return (
            self.client.table("profiles")
            .select("*")
            .eq("is_active", True)
            .not_.is_("encrypted_session", "null")
            .execute()
        )

    async def get_all_active_profiles(self) -> List[Dict[str, Any]]:
        """Get all active user profiles (for worker initialization)"""
        try:
            response = await self._run_sync(self._get_all_active_profiles_sync)
            return response.data or []
        except Exception as e:
            logger.error(f"Failed to get active profiles: {e}")
            return []

    # ==========================================
    # MONITORED CHATS
    # ==========================================

    def _get_monitored_chats_sync(self, user_id: str):
        return (
            self.client.table("monitored_chats")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .execute()
        )

    async def get_monitored_chats(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all monitored chats for a user"""
        try:
            response = await self._run_sync(self._get_monitored_chats_sync, user_id)
            return response.data or []
        except Exception as e:
            logger.error(f"Failed to get monitored chats for {user_id}: {e}")
            return []

    def _is_chat_monitored_sync(self, user_id: str, chat_id: int):
        return (
            self.client.table("monitored_chats")
            .select("id")
            .eq("user_id", user_id)
            .eq("chat_id", chat_id)
            .eq("is_active", True)
            .maybe_single()
            .execute()
        )

    async def is_chat_monitored(self, user_id: str, chat_id: int) -> bool:
        """Check if a chat is being monitored"""
        try:
            response = await self._run_sync(self._is_chat_monitored_sync, user_id, chat_id)
            return response.data is not None
        except Exception as e:
            logger.error(f"Failed to check if chat is monitored: {e}")
            return False

    def _add_monitored_chat_sync(self, chat_data: Dict[str, Any]):
        return (
            self.client.table("monitored_chats")
            .upsert(chat_data, on_conflict="user_id,chat_id")
            .execute()
        )

    async def add_monitored_chat(
        self,
        user_id: str,
        chat_id: int,
        chat_title: str,
        chat_type: str = "private",
    ) -> Dict[str, Any]:
        """Add a chat to monitoring list"""
        try:
            chat_data = {
                "user_id": user_id,
                "chat_id": chat_id,
                "chat_title": chat_title,
                "chat_type": chat_type,
                "is_active": True,
            }
            response = await self._run_sync(self._add_monitored_chat_sync, chat_data)
            logger.info(f"Added monitored chat: {chat_title} for user {user_id}")
            return response.data[0] if response.data else {}
        except Exception as e:
            logger.error(f"Failed to add monitored chat: {e}")
            raise

    def _remove_monitored_chat_sync(self, user_id: str, chat_id: int):
        return (
            self.client.table("monitored_chats")
            .update({"is_active": False})
            .eq("user_id", user_id)
            .eq("chat_id", chat_id)
            .execute()
        )

    async def remove_monitored_chat(self, user_id: str, chat_id: int):
        """Remove a chat from monitoring list"""
        try:
            await self._run_sync(self._remove_monitored_chat_sync, user_id, chat_id)
            logger.info(f"Removed monitored chat {chat_id} for user {user_id}")
        except Exception as e:
            logger.error(f"Failed to remove monitored chat: {e}")
            raise

    def _update_chat_last_message_sync(self, user_id: str, chat_id: int):
        return (
            self.client.table("monitored_chats")
            .update({"last_message_at": datetime.now(timezone.utc).isoformat()})
            .eq("user_id", user_id)
            .eq("chat_id", chat_id)
            .execute()
        )

    async def update_chat_last_message(self, user_id: str, chat_id: int):
        """Update last message timestamp for a chat"""
        try:
            await self._run_sync(self._update_chat_last_message_sync, user_id, chat_id)
        except Exception as e:
            logger.error(f"Failed to update chat last message time: {e}")

    # ==========================================
    # TASKS
    # ==========================================

    def _create_task_sync(self, task_data: Dict[str, Any]):
        return self.client.table("tasks").insert(task_data).execute()

    async def create_task(self, task_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new task."""
        try:
            # Ensure timestamp fields are properly formatted
            if "deadline" in task_data and task_data["deadline"]:
                if isinstance(task_data["deadline"], datetime):
                    task_data["deadline"] = task_data["deadline"].isoformat()

            response = await self._run_sync(self._create_task_sync, task_data)
            task = response.data[0] if response.data else {}
            logger.info(f"Created task: {task.get('content')} [ID: {task.get('id')}]")
            return task
        except Exception as e:
            logger.error(f"Failed to create task: {e}")
            raise

    def _get_active_tasks_sync(self, user_id: str, limit: int):
        return (
            self.client.table("tasks")
            .select("*")
            .eq("user_id", user_id)
            .not_.in_("status", ["done", "cancelled"])
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )

    async def get_active_tasks(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get active (not done/cancelled) tasks for a user"""
        try:
            response = await self._run_sync(self._get_active_tasks_sync, user_id, limit)
            return response.data or []
        except Exception as e:
            logger.error(f"Failed to get active tasks: {e}")
            return []

    def _get_tasks_for_dedup_sync(self, user_id: str, chat_id: int, cutoff_time: str, limit: int):
        return (
            self.client.table("tasks")
            .select("id, content, created_at, deadline")
            .eq("user_id", user_id)
            .eq("chat_id", chat_id)
            .not_.in_("status", ["done", "cancelled"])
            .gte("created_at", cutoff_time)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )

    async def get_tasks_for_dedup(
        self, user_id: str, chat_id: int, hours_back: int = 72, limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get recent tasks from a chat for duplicate detection."""
        try:
            cutoff_time = (datetime.now(timezone.utc) - timedelta(hours=hours_back)).isoformat()
            response = await self._run_sync(
                self._get_tasks_for_dedup_sync, user_id, chat_id, cutoff_time, limit
            )
            tasks = response.data or []

            # Add "created_ago" field for AI prompt (using UTC)
            now = datetime.now(timezone.utc)
            for task in tasks:
                created_at = datetime.fromisoformat(task["created_at"].replace("Z", "+00:00"))
                hours_ago = (now - created_at).total_seconds() / 3600
                task["created_ago"] = f"{hours_ago:.1f} hours ago"

            return tasks
        except Exception as e:
            logger.error(f"Failed to get tasks for dedup: {e}")
            return []

    def _update_task_status_sync(self, task_id: str, status: str, user_id: Optional[str]):
        query = self.client.table("tasks").update({"status": status}).eq("id", task_id)
        if user_id:
            query = query.eq("user_id", user_id)
        return query.execute()

    async def update_task_status(
        self, task_id: str, status: str, user_id: Optional[str] = None
    ):
        """Update task status"""
        try:
            await self._run_sync(self._update_task_status_sync, task_id, status, user_id)
            logger.info(f"Task {task_id} status updated to {status}")
        except Exception as e:
            logger.error(f"Failed to update task status: {e}")
            raise

    def _get_tasks_needing_reminders_sync(self, now_iso: str, reminder_window_iso: str):
        return (
            self.client.table("tasks")
            .select("*, profiles!inner(fcm_token)")
            .not_.in_("status", ["done", "cancelled"])
            .not_.is_("deadline", "null")
            .lte("deadline", reminder_window_iso)
            .gte("deadline", now_iso)
            .execute()
        )

    async def get_tasks_needing_reminders(self) -> List[Dict[str, Any]]:
        """Get tasks that need reminder notifications."""
        try:
            now = datetime.now(timezone.utc)
            reminder_window = now + timedelta(hours=24)
            response = await self._run_sync(
                self._get_tasks_needing_reminders_sync,
                now.isoformat(),
                reminder_window.isoformat()
            )
            return response.data or []
        except Exception as e:
            logger.error(f"Failed to get tasks needing reminders: {e}")
            return []

    # ==========================================
    # TASK NOTIFICATIONS
    # ==========================================

    def _log_notification_sync(self, notification_data: Dict[str, Any]):
        return self.client.table("task_notifications").insert(notification_data).execute()

    async def log_notification(
        self,
        task_id: str,
        notification_type: str,
        success: bool = True,
        fcm_message_id: Optional[str] = None,
        error_message: Optional[str] = None,
    ):
        """Log a sent notification"""
        try:
            notification_data = {
                "task_id": task_id,
                "notification_type": notification_type,
                "success": success,
                "fcm_message_id": fcm_message_id,
                "error_message": error_message,
            }
            await self._run_sync(self._log_notification_sync, notification_data)
        except Exception as e:
            logger.error(f"Failed to log notification: {e}")

    def _has_notification_been_sent_sync(self, task_id: str, notification_type: str):
        return (
            self.client.table("task_notifications")
            .select("id")
            .eq("task_id", task_id)
            .eq("notification_type", notification_type)
            .eq("success", True)
            .maybe_single()
            .execute()
        )

    async def has_notification_been_sent(
        self, task_id: str, notification_type: str
    ) -> bool:
        """Check if a notification has already been sent for a task"""
        try:
            response = await self._run_sync(
                self._has_notification_been_sent_sync, task_id, notification_type
            )
            return response.data is not None
        except Exception as e:
            logger.error(f"Failed to check notification status: {e}")
            return False

    # ==========================================
    # WORKER SESSIONS
    # ==========================================

    def _register_worker_session_sync(self, session_data: Dict[str, Any]):
        return self.client.table("worker_sessions").insert(session_data).execute()

    async def register_worker_session(
        self, user_id: str, worker_instance_id: str
    ) -> str:
        """Register a new worker session"""
        try:
            session_data = {
                "user_id": user_id,
                "worker_instance_id": worker_instance_id,
                "status": "starting",
            }
            response = await self._run_sync(self._register_worker_session_sync, session_data)
            session_id = response.data[0]["id"]
            logger.info(f"Registered worker session {session_id} for user {user_id}")
            return session_id
        except Exception as e:
            logger.error(f"Failed to register worker session: {e}")
            raise

    def _update_worker_status_sync(self, session_id: str, update_data: Dict[str, Any]):
        return (
            self.client.table("worker_sessions")
            .update(update_data)
            .eq("id", session_id)
            .execute()
        )

    async def update_worker_status(
        self,
        session_id: str,
        status: str,
        error_message: Optional[str] = None,
    ):
        """Update worker session status"""
        try:
            update_data = {
                "status": status,
                "last_heartbeat": datetime.now(timezone.utc).isoformat(),
            }
            if error_message:
                update_data["error_message"] = error_message
            if status == "stopped":
                update_data["stopped_at"] = datetime.now(timezone.utc).isoformat()

            await self._run_sync(self._update_worker_status_sync, session_id, update_data)
        except Exception as e:
            logger.error(f"Failed to update worker status: {e}")

    def _heartbeat_sync(self, session_id: str):
        return (
            self.client.table("worker_sessions")
            .update({"last_heartbeat": datetime.now(timezone.utc).isoformat()})
            .eq("id", session_id)
            .execute()
        )

    async def heartbeat(self, session_id: str):
        """Send heartbeat for worker session"""
        try:
            await self._run_sync(self._heartbeat_sync, session_id)
        except Exception as e:
            logger.error(f"Failed to send heartbeat: {e}")


# Example usage
if __name__ == "__main__":
    async def test_db():
        db = DatabaseManager(
            supabase_url="https://your-project.supabase.co",
            supabase_key="your-service-role-key",
        )

        # Test getting profiles
        profiles = await db.get_all_active_profiles()
        print(f"Active profiles: {len(profiles)}")

    # asyncio.run(test_db())
