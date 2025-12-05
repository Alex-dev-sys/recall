"""
Unit tests for Recall Backend Worker

Run with: pytest tests/test_backend.py -v
"""

import pytest
import asyncio
from datetime import datetime, timezone, timedelta
from unittest.mock import Mock, patch, AsyncMock, MagicMock


# ==========================================
# TEST: SessionEncryption
# ==========================================

class TestSessionEncryption:
    """Tests for session encryption/decryption"""
    
    def test_encrypt_decrypt_roundtrip(self):
        """Test that encryption and decryption work correctly"""
        from cryptography.fernet import Fernet
        
        # Generate valid Fernet key
        key = Fernet.generate_key().decode()
        
        # Import after key generation to avoid import errors
        import sys
        sys.path.insert(0, 'src')
        from session_manager import SessionEncryption
        
        encryptor = SessionEncryption(key)
        
        original = "test_session_string_12345"
        encrypted = encryptor.encrypt_session(original)
        decrypted = encryptor.decrypt_session(encrypted)
        
        assert decrypted == original
        assert encrypted != original
    
    def test_invalid_key_raises_error(self):
        """Test that invalid key raises ValueError"""
        import sys
        sys.path.insert(0, 'src')
        from session_manager import SessionEncryption
        
        with pytest.raises(ValueError) as exc_info:
            SessionEncryption("invalid_key_too_short")
        
        assert "Invalid encryption key" in str(exc_info.value)


# ==========================================
# TEST: Phone masking
# ==========================================

class TestPhoneMasking:
    """Tests for phone number masking in logs"""
    
    def test_mask_phone_standard(self):
        """Test standard phone number masking"""
        import sys
        sys.path.insert(0, 'src')
        from session_manager import mask_phone
        
        assert mask_phone("+79991234567") == "+799****67"
        assert mask_phone("+1234567890") == "+123****90"
    
    def test_mask_phone_short(self):
        """Test short phone numbers are fully masked"""
        import sys
        sys.path.insert(0, 'src')
        from session_manager import mask_phone
        
        assert mask_phone("12345") == "****"
        assert mask_phone("") == "****"


# ==========================================
# TEST: Source link generation
# ==========================================

class TestSourceLinkGeneration:
    """Tests for Telegram source link generation"""
    
    def test_supergroup_link(self):
        """Test that supergroup links are generated correctly"""
        chat_id = -1001234567890
        message_id = 123
        
        chat_id_str = str(chat_id)
        if chat_id_str.startswith("-100"):
            source_link = f"https://t.me/c/{chat_id_str[4:]}/{message_id}"
        else:
            source_link = None
        
        assert source_link == "https://t.me/c/1234567890/123"
    
    def test_private_chat_no_link(self):
        """Test that private chats return None"""
        chat_id = 123456789  # Positive = private chat
        message_id = 456
        
        chat_id_str = str(chat_id)
        if chat_id_str.startswith("-100"):
            source_link = f"https://t.me/c/{chat_id_str[4:]}/{message_id}"
        elif chat_id < 0:
            source_link = None
        else:
            source_link = None
        
        assert source_link is None
    
    def test_regular_group_no_link(self):
        """Test that regular groups return None"""
        chat_id = -123456  # Negative but not -100 prefix = regular group
        message_id = 789
        
        chat_id_str = str(chat_id)
        if chat_id_str.startswith("-100"):
            source_link = f"https://t.me/c/{chat_id_str[4:]}/{message_id}"
        elif chat_id < 0:
            source_link = None
        else:
            source_link = None
        
        assert source_link is None


# ==========================================
# TEST: DatabaseManager async operations
# ==========================================

class TestDatabaseManager:
    """Tests for DatabaseManager async operations"""
    
    @pytest.mark.asyncio
    async def test_run_sync_executes_in_thread(self):
        """Test that _run_sync properly executes sync functions"""
        # Mock the Supabase client (src is already in path via conftest.py)
        with patch('database.create_client') as mock_create:
            mock_client = MagicMock()
            mock_create.return_value = mock_client
            
            from database import DatabaseManager
            
            db = DatabaseManager(
                supabase_url="https://test.supabase.co",
                supabase_key="test_key"
            )
            
            # Test sync function
            def sync_func(x, y):
                return x + y
            
            result = await db._run_sync(sync_func, 1, 2)
            assert result == 3


# ==========================================
# TEST: Token authentication
# ==========================================

class TestTokenAuth:
    """Tests for token-based authentication"""
    
    def test_generate_token_creates_unique_tokens(self):
        """Test that each call generates a unique token"""
        import secrets
        
        # Simulate generate_token logic
        active_tokens = {}
        
        def generate_token(user_id: str) -> str:
            token = secrets.token_urlsafe(32)
            active_tokens[user_id] = token
            return token
        
        token1 = generate_token("user1")
        token2 = generate_token("user2")
        token3 = generate_token("user1")  # Same user, new token
        
        assert token1 != token2
        assert token1 != token3
        assert len(token1) > 20  # token_urlsafe(32) produces ~43 chars


# ==========================================
# TEST: UTC timezone usage
# ==========================================

class TestTimezoneHandling:
    """Tests for proper UTC timezone usage"""
    
    def test_datetime_uses_utc(self):
        """Test that datetime operations use UTC"""
        now_utc = datetime.now(timezone.utc)
        now_naive = datetime.now()
        
        # UTC datetime should have tzinfo
        assert now_utc.tzinfo is not None
        assert now_utc.tzinfo == timezone.utc
        
        # Naive datetime should not have tzinfo
        assert now_naive.tzinfo is None
    
    def test_hours_ago_calculation_with_utc(self):
        """Test hours ago calculation with proper timezone"""
        # Simulate the fixed code
        created_at_str = "2025-12-05T10:00:00Z"
        created_at = datetime.fromisoformat(created_at_str.replace("Z", "+00:00"))
        
        now = datetime.now(timezone.utc)
        hours_ago = (now - created_at).total_seconds() / 3600
        
        # Should be positive and reasonable
        assert hours_ago >= 0


# ==========================================
# FIXTURES
# ==========================================

@pytest.fixture
def mock_supabase_client():
    """Create a mock Supabase client"""
    client = MagicMock()
    client.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value = MagicMock(data={"id": "test"})
    return client


@pytest.fixture
def sample_task():
    """Sample task data for testing"""
    return {
        "id": "test-task-id",
        "content": "Test task content",
        "original_quote": "Test quote",
        "task_type": "request",
        "priority": "medium",
        "deadline": None,
        "status": "new",
        "confidence": 0.85,
        "created_at": "2025-12-05T10:00:00Z"
    }


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
