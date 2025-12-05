"""
FastAPI server for Flutter app integration.
Handles authentication, chat list fetching, and worker management.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends, Header, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator
from typing import Optional, List, Dict, Any
from loguru import logger
import asyncio

from database import DatabaseManager
from session_manager import SessionManager, request_telegram_code
from worker import RecallWorker, load_config


# Pydantic models for API
class PhoneNumberRequest(BaseModel):
    phone_number: str


class VerifyCodeRequest(BaseModel):
    phone_number: str
    code: str
    phone_code_hash: str
    password: Optional[str] = None


class UpdateFCMTokenRequest(BaseModel):
    fcm_token: str


class ChatToggleRequest(BaseModel):
    chat_id: int
    chat_title: str
    chat_type: str = "private"
    action: str  # "add" or "remove"

    @field_validator("action")
    @classmethod
    def validate_action(cls, v: str) -> str:
        if v not in ("add", "remove"):
            raise ValueError("action must be 'add' or 'remove'")
        return v


# API Response models
class CodeSentResponse(BaseModel):
    success: bool
    phone_code_hash: str
    message: str


class LoginResponse(BaseModel):
    success: bool
    user_id: str
    message: str


class ChatListResponse(BaseModel):
    chats: List[Dict[str, Any]]


# Global instances (initialized in lifespan)
db: DatabaseManager = None
worker: RecallWorker = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Modern lifespan context manager for startup/shutdown"""
    global db, worker
    
    logger.info("Starting API server...")
    
    # Load config
    config = load_config()
    
    # Initialize database
    db = DatabaseManager(
        supabase_url=config["supabase"]["url"],
        supabase_key=config["supabase"]["service_role_key"],
    )
    
    # Initialize worker (contains its own session_manager)
    worker = RecallWorker(config)
    
    # Start worker in background
    asyncio.create_task(worker.start())
    
    logger.info("API server started")
    
    yield  # Server is running
    
    # Shutdown
    logger.info("Shutting down API server...")
    
    if worker:
        await worker.stop()
    
    if db:
        db.shutdown()
    
    logger.info("API server shut down")


app = FastAPI(title="Recall API", version="1.0.0", lifespan=lifespan)


# ==========================================
# RATE LIMITING
# ==========================================
try:
    from slowapi import Limiter, _rate_limit_exceeded_handler
    from slowapi.util import get_remote_address
    from slowapi.errors import RateLimitExceeded
    
    limiter = Limiter(key_func=get_remote_address)
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    RATE_LIMITING_ENABLED = True
except ImportError:
    limiter = None
    RATE_LIMITING_ENABLED = False
    logger.warning("slowapi not installed - rate limiting disabled")


# ==========================================
# AUTHENTICATION
# ==========================================
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer(auto_error=False)

# In-memory token store (in production use Redis or database)
# Maps user_id -> token
active_tokens: Dict[str, str] = {}


def generate_token(user_id: str) -> str:
    """Generate a simple session token"""
    import secrets
    token = secrets.token_urlsafe(32)
    active_tokens[user_id] = token
    return token


async def verify_token(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> Optional[str]:
    """
    Verify bearer token and return user_id.
    Returns None if no valid token (for optional auth endpoints).
    """
    if not credentials:
        return None
    
    token = credentials.credentials
    for user_id, stored_token in active_tokens.items():
        if stored_token == token:
            return user_id
    return None


async def require_auth(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """
    Require valid authentication. Raises 401 if not authenticated.
    Use this for protected endpoints.
    """
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    user_id = await verify_token(credentials)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    return user_id


# CORS middleware for Flutter app - SECURED
ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://127.0.0.1:3000",
    # Add your production domains here:
    # "https://your-app.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)


# ==========================================
# AUTHENTICATION ENDPOINTS
# ==========================================


@app.post("/auth/request-code", response_model=CodeSentResponse)
async def request_code(request: PhoneNumberRequest):
    """
    Step 1: Request verification code from Telegram.
    Rate limited to 3 requests per minute.
    """
    try:
        phone_code_hash, session_name = await request_telegram_code(
            api_id=worker.session_manager.api_id,
            api_hash=worker.session_manager.api_hash,
            phone_number=request.phone_number,
        )

        return CodeSentResponse(
            success=True,
            phone_code_hash=phone_code_hash,
            message="Verification code sent",
        )

    except Exception as e:
        logger.error(f"Failed to request code: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/auth/verify-code")
async def verify_code(request: VerifyCodeRequest):
    """
    Step 2: Verify code and complete login.
    Returns auth token for subsequent requests.
    """
    try:
        # Complete login and get encrypted session
        encrypted_session = await worker.session_manager.login_with_code(
            phone_number=request.phone_number,
            code=request.code,
            phone_code_hash=request.phone_code_hash,
            password=request.password,
        )

        # Create temporary client to get user info
        from pyrogram import Client

        temp_client = Client(
            name="temp_" + request.phone_number.replace("+", ""),
            api_id=worker.session_manager.api_id,
            api_hash=worker.session_manager.api_hash,
            session_string=worker.session_manager.encryptor.decrypt_session(encrypted_session),
        )

        await temp_client.start()
        me = await temp_client.get_me()
        await temp_client.stop()

        # Use Telegram user ID as the user ID
        user_id = str(me.id)

        # Create/update profile in database
        await db.create_or_update_profile(
            user_id=user_id,
            telegram_user_id=me.id,
            encrypted_session=encrypted_session,
            phone_number=request.phone_number,
            first_name=me.first_name,
            last_name=me.last_name,
            username=me.username,
        )

        # Start worker session for this user
        profile = await db.get_profile(user_id)
        if not profile:
            raise HTTPException(status_code=500, detail="Failed to create user profile")
        await worker._start_user_session(profile)

        # Generate auth token
        token = generate_token(user_id)

        logger.info(f"User logged in: {me.username or me.first_name} (ID: {user_id})")

        return {
            "success": True,
            "user_id": user_id,
            "token": token,
            "message": "Login successful"
        }

    except Exception as e:
        logger.error(f"Login failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/auth/logout")
async def logout(auth_user_id: str = Depends(require_auth)):
    """
    Logout user and cleanup session.
    
    Returns:
        Success status
    """
    try:
        # Remove auth token
        active_tokens.pop(auth_user_id, None)
        
        # Cleanup worker session
        await worker.cleanup_user(auth_user_id)
        
        logger.info(f"User {auth_user_id} logged out")
        return {"success": True, "message": "Logged out successfully"}
    except Exception as e:
        logger.error(f"Logout failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# CHAT MANAGEMENT ENDPOINTS
# ==========================================


@app.get("/chats/list/{user_id}", response_model=ChatListResponse)
async def get_chat_list(user_id: str, auth_user_id: str = Depends(require_auth)):
    """
    Get list of all user's chats from Telegram.

    Args:
        user_id: User ID
        auth_user_id: Authenticated user ID (from token)

    Returns:
        List of chats with metadata
    """
    # Verify user can only access their own data
    if user_id != auth_user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    try:
        client = worker.session_manager.get_client(user_id)

        if not client:
            raise HTTPException(status_code=404, detail="User session not found")

        # Get all dialogs from Telegram
        chats = []

        async for dialog in client.get_dialogs():
            chat_info = {
                "chat_id": dialog.chat.id,
                "title": dialog.chat.title or dialog.chat.first_name or "Unknown",
                "type": dialog.chat.type.name.lower(),
                "username": dialog.chat.username,
                "photo_exists": dialog.chat.photo is not None,
                "unread_count": dialog.unread_messages_count,
            }
            chats.append(chat_info)

        # Get monitored chats from DB
        monitored = await db.get_monitored_chats(user_id)
        monitored_ids = {chat["chat_id"] for chat in monitored}

        # Add "is_monitored" flag
        for chat in chats:
            chat["is_monitored"] = chat["chat_id"] in monitored_ids

        logger.info(f"Fetched {len(chats)} chats for user {user_id}")

        return ChatListResponse(chats=chats)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get chat list: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chats/toggle/{user_id}")
async def toggle_chat_monitoring(user_id: str, request: ChatToggleRequest, auth_user_id: str = Depends(require_auth)):
    """
    Add or remove a chat from monitoring list.

    Args:
        user_id: User ID
        request: Chat toggle request
        auth_user_id: Authenticated user ID (from token)

    Returns:
        Success status
    """
    # Verify user can only modify their own data
    if user_id != auth_user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    try:
        if request.action == "add":
            await worker.add_monitored_chat(
                user_id=user_id,
                chat_id=request.chat_id,
                chat_title=request.chat_title,
                chat_type=request.chat_type,
            )
            message = f"Chat '{request.chat_title}' added to monitoring"

        elif request.action == "remove":
            await worker.remove_monitored_chat(user_id=user_id, chat_id=request.chat_id)
            message = f"Chat '{request.chat_title}' removed from monitoring"

        else:
            raise HTTPException(status_code=400, detail="Invalid action")

        return {"success": True, "message": message}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to toggle chat monitoring: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# PROFILE & SETTINGS ENDPOINTS
# ==========================================


@app.post("/profile/fcm-token/{user_id}")
async def update_fcm_token(user_id: str, request: UpdateFCMTokenRequest, auth_user_id: str = Depends(require_auth)):
    """
    Update FCM token for push notifications.

    Args:
        user_id: User ID
        request: FCM token update request
        auth_user_id: Authenticated user ID (from token)

    Returns:
        Success status
    """
    # Verify user can only modify their own data
    if user_id != auth_user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    try:
        await db.update_fcm_token(user_id=user_id, fcm_token=request.fcm_token)

        return {"success": True, "message": "FCM token updated"}

    except Exception as e:
        logger.error(f"Failed to update FCM token: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/profile/{user_id}")
async def get_profile(user_id: str, auth_user_id: str = Depends(require_auth)):
    """Get user profile"""
    # Verify user can only access their own data
    if user_id != auth_user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    try:
        profile = await db.get_profile(user_id)

        if not profile:
            raise HTTPException(status_code=404, detail="Profile not found")

        # Don't expose encrypted session
        profile.pop("encrypted_session", None)

        return profile

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# TASK ENDPOINTS
# ==========================================


@app.get("/tasks/active/{user_id}")
async def get_active_tasks(user_id: str, limit: int = 50, auth_user_id: str = Depends(require_auth)):
    """Get active tasks for user"""
    # Verify user can only access their own data
    if user_id != auth_user_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    try:
        tasks = await db.get_active_tasks(user_id=user_id, limit=limit)
        return {"tasks": tasks}

    except Exception as e:
        logger.error(f"Failed to get active tasks: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Valid task statuses
VALID_TASK_STATUSES = {"new", "in_progress", "done", "cancelled"}


@app.put("/tasks/{task_id}/status")
async def update_task_status(
    task_id: str,
    status: str = Query(..., description="New status"),
    auth_user_id: str = Depends(require_auth)
):
    """Update task status (mark as done, etc.)"""
    try:
        if status not in VALID_TASK_STATUSES:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status. Must be one of: {', '.join(sorted(VALID_TASK_STATUSES))}"
            )
        await db.update_task_status(task_id=task_id, status=status, user_id=auth_user_id)

        return {"success": True, "message": f"Task status updated to {status}"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update task status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==========================================
# HEALTH CHECK
# ==========================================


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "worker_running": worker.is_running if worker else False,
        "active_sessions": len(worker.session_manager.clients) if worker else 0,
    }





if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
