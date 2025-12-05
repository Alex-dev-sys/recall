"""
Session Manager for Pyrogram clients.
Handles encryption/decryption of sessions and manages multiple user clients.
"""

import asyncio
import base64
from typing import Dict, Optional, List
from datetime import datetime
from loguru import logger
from cryptography.fernet import Fernet
from pyrogram import Client
from pyrogram.errors import (
    SessionPasswordNeeded,
    PhoneCodeInvalid,
    PhoneCodeExpired,
    FloodWait,
)


class SessionEncryption:
    """Handles encryption/decryption of Pyrogram session strings"""

    def __init__(self, encryption_key: str):
        """
        Args:
            encryption_key: Fernet key (44-byte base64-encoded string from Fernet.generate_key())
        """
        try:
            # Fernet keys are 44 characters base64-encoded (32 bytes when decoded)
            key_bytes = encryption_key.encode() if isinstance(encryption_key, str) else encryption_key
            
            # Validate it's a proper Fernet key by trying to create a Fernet instance
            self.cipher = Fernet(key_bytes)
            
        except Exception as e:
            raise ValueError(
                f"Invalid encryption key. Key must be a valid Fernet key "
                f"(generate with: Fernet.generate_key()). Error: {e}"
            )

    def encrypt_session(self, session_string: str) -> str:
        """
        Encrypt Pyrogram session string.

        Args:
            session_string: Plain session string from Pyrogram

        Returns:
            Encrypted session string (base64)
        """
        try:
            encrypted = self.cipher.encrypt(session_string.encode())
            return base64.urlsafe_b64encode(encrypted).decode()
        except Exception as e:
            logger.error(f"Session encryption failed: {e}")
            raise

    def decrypt_session(self, encrypted_session: str) -> str:
        """
        Decrypt Pyrogram session string.

        Args:
            encrypted_session: Encrypted session string from database

        Returns:
            Plain session string for Pyrogram
        """
        try:
            encrypted_bytes = base64.urlsafe_b64decode(encrypted_session.encode())
            decrypted = self.cipher.decrypt(encrypted_bytes)
            return decrypted.decode()
        except Exception as e:
            logger.error(f"Session decryption failed: {e}")
            raise


class SessionManager:
    """
    Manages multiple Pyrogram client sessions for different users.
    """

    def __init__(
        self,
        api_id: int,
        api_hash: str,
        encryption_key: str,
        workdir: str = "./sessions",
    ):
        """
        Args:
            api_id: Telegram API ID
            api_hash: Telegram API hash
            encryption_key: Key for session encryption/decryption
            workdir: Directory to store session files
        """
        self.api_id = api_id
        self.api_hash = api_hash
        self.encryptor = SessionEncryption(encryption_key)
        self.workdir = workdir

        # Active clients: {user_id: Client}
        self.clients: Dict[str, Client] = {}

        # Client status: {user_id: {"status": "running", "started_at": datetime}}
        self.client_status: Dict[str, Dict] = {}

    async def create_new_session(
        self, phone_number: str, session_name: Optional[str] = None
    ) -> tuple[Client, str]:
        """
        Create a new Telegram session (for initial login).

        Args:
            phone_number: User's phone number
            session_name: Optional session name (default: phone_number)

        Returns:
            Tuple of (Client instance, session_string)

        Note:
            This client is NOT connected yet. Use request_code() and sign_in() manually.
        """
        session_name = session_name or phone_number.replace("+", "")

        client = Client(
            name=session_name,
            api_id=self.api_id,
            api_hash=self.api_hash,
            workdir=self.workdir,
            phone_number=phone_number,
        )

        logger.info(f"Created new session for {phone_number}")
        return client, session_name

    async def login_with_code(
        self,
        phone_number: str,
        code: str,
        phone_code_hash: str,
        password: Optional[str] = None,
    ) -> str:
        """
        Complete login flow with verification code.

        Args:
            phone_number: User's phone number
            code: Verification code from Telegram
            phone_code_hash: Hash from request_code
            password: 2FA password if enabled

        Returns:
            Encrypted session string

        Raises:
            PhoneCodeInvalid: Invalid verification code
            SessionPasswordNeeded: 2FA password required
        """
        session_name = phone_number.replace("+", "")
        client = Client(
            name=session_name,
            api_id=self.api_id,
            api_hash=self.api_hash,
            workdir=self.workdir,
            phone_number=phone_number,
        )

        try:
            await client.connect()

            # Sign in with code
            signed_in = await client.sign_in(phone_number, phone_code_hash, code)

            # Check if 2FA is required
            if isinstance(signed_in, bool) and not signed_in:
                if not password:
                    raise SessionPasswordNeeded("2FA password required")
                await client.check_password(password)

            # Export session string
            session_string = await client.export_session_string()

            # Encrypt before storing
            encrypted_session = self.encryptor.encrypt_session(session_string)

            await client.disconnect()

            logger.info(f"Successfully logged in: {phone_number}")
            return encrypted_session

        except Exception as e:
            logger.error(f"Login failed for {phone_number}: {e}")
            await client.disconnect()
            raise

    async def load_client(self, user_id: str, encrypted_session: str) -> Client:
        """
        Load and start a Pyrogram client from encrypted session.

        Args:
            user_id: User ID (from database)
            encrypted_session: Encrypted session string

        Returns:
            Connected Pyrogram Client instance
        """
        if user_id in self.clients:
            logger.warning(f"Client for user {user_id} already exists")
            return self.clients[user_id]

        try:
            # Decrypt session
            session_string = self.encryptor.decrypt_session(encrypted_session)

            # Create client
            client = Client(
                name=f"user_{user_id}",
                api_id=self.api_id,
                api_hash=self.api_hash,
                workdir=self.workdir,
                session_string=session_string,
            )

            # Connect
            await client.start()

            # Store client
            self.clients[user_id] = client
            self.client_status[user_id] = {
                "status": "running",
                "started_at": datetime.now(),
            }

            # Get user info
            me = await client.get_me()
            logger.info(
                f"Loaded client for user {user_id}: @{me.username} ({me.first_name})"
            )

            return client

        except Exception as e:
            logger.error(f"Failed to load client for user {user_id}: {e}")
            self.client_status[user_id] = {
                "status": "error",
                "error": str(e),
                "failed_at": datetime.now(),
            }
            raise

    async def unload_client(self, user_id: str):
        """
        Stop and remove a client from active sessions.

        Args:
            user_id: User ID
        """
        if user_id not in self.clients:
            logger.warning(f"No client found for user {user_id}")
            return

        try:
            client = self.clients[user_id]
            await client.stop()

            del self.clients[user_id]
            self.client_status[user_id] = {
                "status": "stopped",
                "stopped_at": datetime.now(),
            }

            logger.info(f"Unloaded client for user {user_id}")

        except Exception as e:
            logger.error(f"Failed to unload client for user {user_id}: {e}")

    async def reload_client(self, user_id: str, encrypted_session: str):
        """
        Reload a client (stop old one and start new one).

        Args:
            user_id: User ID
            encrypted_session: New encrypted session string
        """
        if user_id in self.clients:
            await self.unload_client(user_id)

        await self.load_client(user_id, encrypted_session)

    def get_client(self, user_id: str) -> Optional[Client]:
        """
        Get active client for user.

        Args:
            user_id: User ID

        Returns:
            Client instance or None if not loaded
        """
        return self.clients.get(user_id)

    def get_all_clients(self) -> Dict[str, Client]:
        """Get all active clients"""
        return self.clients.copy()

    def get_status(self, user_id: str) -> Optional[Dict]:
        """Get client status for user"""
        return self.client_status.get(user_id)

    def get_all_statuses(self) -> Dict[str, Dict]:
        """Get all client statuses"""
        return self.client_status.copy()

    async def shutdown_all(self):
        """Stop all active clients"""
        logger.info("Shutting down all clients...")

        tasks = []
        for user_id in list(self.clients.keys()):
            tasks.append(self.unload_client(user_id))

        await asyncio.gather(*tasks, return_exceptions=True)

        logger.info("All clients stopped")


# Helper functions for session operations
def mask_phone(phone: str) -> str:
    """Mask phone number for logging (show first 4 and last 2 chars)"""
    if len(phone) < 7:
        return "****"
    return phone[:4] + "****" + phone[-2:]


async def request_telegram_code(
    api_id: int, api_hash: str, phone_number: str, max_retries: int = 2
) -> tuple[str, str]:
    """
    Request verification code from Telegram (for new logins).

    Args:
        api_id: Telegram API ID
        api_hash: Telegram API hash
        phone_number: User's phone number
        max_retries: Maximum retry attempts on FloodWait

    Returns:
        Tuple of (phone_code_hash, session_name)
    """
    session_name = phone_number.replace("+", "")

    client = Client(
        name=session_name,
        api_id=api_id,
        api_hash=api_hash,
        workdir="./temp_sessions",
        phone_number=phone_number,
    )

    retries = 0
    while retries <= max_retries:
        try:
            await client.connect()
            sent_code = await client.send_code(phone_number)

            phone_code_hash = sent_code.phone_code_hash

            await client.disconnect()

            logger.info(f"Verification code sent to {mask_phone(phone_number)}")
            return phone_code_hash, session_name

        except FloodWait as e:
            retries += 1
            if retries > max_retries:
                logger.error(f"FloodWait exceeded max retries for {mask_phone(phone_number)}")
                raise
            
            wait_time = min(e.value, 300)  # Cap at 5 minutes
            logger.warning(f"FloodWait: waiting {wait_time}s before retry {retries}/{max_retries}")
            await asyncio.sleep(wait_time)
            
        except Exception as e:
            logger.error(f"Failed to request code for {mask_phone(phone_number)}: {e}")
            try:
                await client.disconnect()
            except Exception:
                pass
            raise


# Example usage
if __name__ == "__main__":

    async def test_session_manager():
        # Test encryption
        key = Fernet.generate_key().decode()
        encryptor = SessionEncryption(key)

        test_session = "test_session_string_123"
        encrypted = encryptor.encrypt_session(test_session)
        decrypted = encryptor.decrypt_session(encrypted)

        assert decrypted == test_session
        print("✓ Encryption/decryption works")

        # Test session manager (requires real credentials)
        # manager = SessionManager(
        #     api_id=12345,
        #     api_hash="your_hash",
        #     encryption_key=key
        # )
        # ...

    asyncio.run(test_session_manager())
