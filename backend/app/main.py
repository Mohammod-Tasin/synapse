"""
FastAPI application entry point with all authentication and onboarding endpoints.
Provides a complete RESTful API for user authentication and focus preferences.
"""
from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from datetime import datetime, timedelta, time
from bson.objectid import ObjectId

from app.config import settings
from app.database import connect_to_mongo, close_mongo_connection, get_database
from app.schemas import (
    RegisterRequest, LoginRequest, TokenResponse, UserResponse,
    RegisterResponse, VerifyEmailRequest, ResendVerificationRequest,
    ForgotPasswordRequest, ResetPasswordRequest,
    MessageResponse,
    OnboardingRequest, OnboardingResponse, ErrorResponse,
    FocusSessionEventRequest, BlockScreenEventRequest, PointEventResponse,
    LeaderboardEntry, LeaderboardResponse,
    TodayStatsResponse, AnalyticsDay, AnalyticsResponse,
)
from app.auth import (
    verify_password, get_password_hash, create_access_token, 
    verify_token, extract_token_from_header
)
from app.models import User
from app.email_service import (
    generate_verification_code,
    hash_verification_code,
    send_password_reset_code,
    send_verification_code,
    verify_hashed_code,
)
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _to_object_id(user_id: str) -> ObjectId:
    try:
        return ObjectId(user_id)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user id in token"
        ) from exc


def _ensure_user_points_fields(db, user_object_id: ObjectId) -> dict:
    user_doc = db.users.find_one({"_id": user_object_id})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    set_defaults = {}
    for field in (
        "total_points",
        "lifetime_focus_minutes",
        "lifetime_focus_sessions",
        "lifetime_block_screens",
        "lifetime_points_lost",
    ):
        if field not in user_doc:
            set_defaults[field] = 0

    if set_defaults:
        set_defaults["updated_at"] = datetime.utcnow()
        db.users.update_one(
            {"_id": user_object_id},
            {"$set": set_defaults}
        )
        user_doc = db.users.find_one({"_id": user_object_id})

    return user_doc


def _aggregate_day_stats(db, user_object_id: ObjectId, start_dt: datetime, end_dt: datetime) -> dict:
    focus_pipeline = [
        {
            "$match": {
                "user_id": user_object_id,
                "created_at": {"$gte": start_dt, "$lt": end_dt},
            }
        },
        {
            "$group": {
                "_id": None,
                "count": {"$sum": 1},
                "minutes": {"$sum": "$duration_minutes"},
                "points": {"$sum": "$points_delta"},
            }
        },
    ]

    block_pipeline = [
        {
            "$match": {
                "user_id": user_object_id,
                "created_at": {"$gte": start_dt, "$lt": end_dt},
            }
        },
        {
            "$group": {
                "_id": None,
                "count": {"$sum": 1},
                "points_lost": {"$sum": {"$multiply": ["$points_delta", -1]}},
            }
        },
    ]

    focus_summary = next(iter(db.focus_sessions.aggregate(focus_pipeline)), None)
    block_summary = next(iter(db.block_events.aggregate(block_pipeline)), None)

    focus_sessions_count = int((focus_summary or {}).get("count", 0))
    focus_minutes = int((focus_summary or {}).get("minutes", 0))
    focus_points_gained = int((focus_summary or {}).get("points", 0))
    block_screens_count = int((block_summary or {}).get("count", 0))
    points_lost = int((block_summary or {}).get("points_lost", 0))

    return {
        "focus_sessions_count": focus_sessions_count,
        "focus_minutes": focus_minutes,
        "focus_points_gained": focus_points_gained,
        "block_screens_count": block_screens_count,
        "points_lost": points_lost,
        "net_points": focus_points_gained - points_lost,
    }


def _analytics_message(series: list[dict], trend: str) -> str:
    if not series:
        return "Start today. Even 10 focused minutes can change your week."

    last = series[-1]
    if last["focus_minutes"] >= 60 and last["block_screens_count"] == 0:
        return "Excellent discipline today. Keep this rhythm and your ranking will keep rising."

    if trend == "improving":
        return "Great progress. Your consistency is building real momentum."

    if trend == "declining":
        return "Progress dipped recently. Reset with one deep focus session now and bounce back."

    return "Stay steady. Small focused wins every day lead to major long-term growth."


def _issue_and_store_verification_code(db, user_doc: dict) -> None:
    """Generate, persist and send a fresh email verification code."""
    verification_code = generate_verification_code()
    expires_at = datetime.utcnow() + timedelta(
        minutes=settings.EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES
    )

    db.users.update_one(
        {"_id": user_doc["_id"]},
        {
            "$set": {
                "email_verification_code_hash": hash_verification_code(
                    email=user_doc["email"],
                    code=verification_code,
                ),
                "email_verification_expires_at": expires_at,
                "email_verification_attempts": 0,
                "updated_at": datetime.utcnow(),
            },
            "$unset": {
                "email_verification_code": "",  # Cleanup legacy plain-text field
            },
        }
    )

    send_verification_code(user_doc["email"], verification_code)


def _issue_and_store_password_reset_code(db, user_doc: dict) -> None:
    """Generate, persist and send a fresh password reset code."""
    reset_code = generate_verification_code()
    expires_at = datetime.utcnow() + timedelta(
        minutes=settings.PASSWORD_RESET_CODE_EXPIRE_MINUTES
    )

    db.users.update_one(
        {"_id": user_doc["_id"]},
        {
            "$set": {
                "password_reset_code_hash": hash_verification_code(
                    email=user_doc["email"],
                    code=reset_code,
                ),
                "password_reset_expires_at": expires_at,
                "password_reset_attempts": 0,
                "updated_at": datetime.utcnow(),
            },
        }
    )

    send_password_reset_code(user_doc["email"], reset_code)

# Create FastAPI app
app = FastAPI(
    title=settings.API_TITLE,
    version=settings.API_VERSION,
    openapi_url=f"{settings.API_PREFIX}/openapi.json"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Lifecycle events
@app.on_event("startup")
async def startup_event():
    """Connect to MongoDB on app startup."""
    await connect_to_mongo()
    logger.info("Application started")


@app.on_event("shutdown")
async def shutdown_event():
    """Close MongoDB connection on app shutdown."""
    await close_mongo_connection()
    logger.info("Application shutdown")


# Dependency: Get current user from JWT token
async def get_current_user(authorization: str = Header(None)) -> dict:
    """
    Verify JWT token and return the current user.
    This is used as a dependency in protected endpoints.
    """
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing"
        )
    
    token = extract_token_from_header(authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format"
        )
    
    payload = verify_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing user ID"
        )
    
    return {"user_id": user_id}


# ======================== Health Check ========================
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


# ======================== Auth Endpoints ========================
@app.post(
    f"{settings.API_PREFIX}/auth/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Authentication"]
)
async def register(request: RegisterRequest):
    """
    Register a new user.
    
    - **email**: User email (must be valid and unique)
    - **password**: Password (min 8 chars, 1 uppercase, 1 digit)
    - **name**: User's full name
    
    Sends a verification code to user's email on success.
    """
    db = get_database()
    
    # Check if user already exists
    existing_user = db.users.find_one({"email": request.email})
    if existing_user:
        if existing_user.get("email_verified", False):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )

        db.users.update_one(
            {"_id": existing_user["_id"]},
            {
                "$set": {
                    "hashed_password": get_password_hash(request.password),
                    "name": request.name,
                    "updated_at": datetime.utcnow(),
                }
            }
        )

        refreshed_user_doc = db.users.find_one({"_id": existing_user["_id"]})

        try:
            _issue_and_store_verification_code(db, refreshed_user_doc)
        except Exception as e:
            logger.error(f"Failed to send verification code: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send verification email"
            )

        return RegisterResponse(
            message="Verification code sent to your email",
            email=request.email,
        )
    
    # Hash password and create user
    hashed_password = get_password_hash(request.password)
    user = User(
        email=request.email,
        hashed_password=hashed_password,
        name=request.name,
        email_verified=False,
    )
    
    # Insert user into database
    result = db.users.insert_one(user.to_dict())
    user.id = str(result.inserted_id)

    inserted_user_doc = db.users.find_one({"_id": result.inserted_id})
    
    try:
        _issue_and_store_verification_code(db, inserted_user_doc)
    except Exception as e:
        logger.error(f"Failed to send verification code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send verification email"
        )

    logger.info(f"New user registered (verification pending): {request.email}")

    return RegisterResponse(
        message="Verification code sent to your email",
        email=request.email,
    )


@app.post(
    f"{settings.API_PREFIX}/auth/resend-verification",
    response_model=MessageResponse,
    tags=["Authentication"]
)
async def resend_verification(request: ResendVerificationRequest):
    """Resend email verification code for unverified users."""
    db = get_database()
    user_doc = db.users.find_one({"email": request.email})

    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    if user_doc.get("email_verified", False):
        return MessageResponse(message="Email already verified")

    try:
        _issue_and_store_verification_code(db, user_doc)
    except Exception as e:
        logger.error(f"Failed to resend verification code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send verification email"
        )

    return MessageResponse(message="Verification code resent successfully")


@app.post(
    f"{settings.API_PREFIX}/auth/verify-email",
    response_model=TokenResponse,
    tags=["Authentication"]
)
async def verify_email(request: VerifyEmailRequest):
    """Verify email using 6-digit code and return auth token."""
    db = get_database()

    user_doc = db.users.find_one({"email": request.email})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    if user_doc.get("email_verified", False):
        user = User.from_dict(user_doc)
        access_token = create_access_token(
            data={"sub": user.id, "email": user.email}
        )
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            user=UserResponse(
                id=user.id,
                email=user.email,
                name=user.name,
                onboarding_completed=user.onboarding_completed,
                created_at=user.created_at,
                total_points=user.total_points,
            )
        )

    stored_hash = user_doc.get("email_verification_code_hash")
    legacy_plain_code = user_doc.get("email_verification_code")
    expires_at = user_doc.get("email_verification_expires_at")
    attempts = int(user_doc.get("email_verification_attempts", 0))

    if attempts >= settings.EMAIL_VERIFICATION_MAX_ATTEMPTS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many invalid attempts. Please request a new code."
        )

    if (not stored_hash and not legacy_plain_code) or not expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code is not available. Please register again."
        )

    if datetime.utcnow() > expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code expired. Please register again."
        )

    is_valid = False
    if stored_hash:
        is_valid = verify_hashed_code(
            email=request.email,
            code=request.code,
            expected_hash=stored_hash,
        )
    elif legacy_plain_code:
        is_valid = request.code == legacy_plain_code

    if not is_valid:
        db.users.update_one(
            {"_id": user_doc["_id"]},
            {
                "$inc": {"email_verification_attempts": 1},
                "$set": {"updated_at": datetime.utcnow()},
            },
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid verification code"
        )

    db.users.update_one(
        {"_id": user_doc["_id"]},
        {
            "$set": {
                "email_verified": True,
                "email_verification_attempts": 0,
                "updated_at": datetime.utcnow(),
            },
            "$unset": {
                "email_verification_code": "",
                "email_verification_code_hash": "",
                "email_verification_expires_at": "",
            }
        }
    )

    verified_user_doc = db.users.find_one({"_id": user_doc["_id"]})
    user = User.from_dict(verified_user_doc)
    access_token = create_access_token(
        data={"sub": user.id, "email": user.email}
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            onboarding_completed=user.onboarding_completed,
            created_at=user.created_at,
            total_points=user.total_points,
        )
    )


@app.post(
    f"{settings.API_PREFIX}/auth/login",
    response_model=TokenResponse,
    tags=["Authentication"]
)
async def login(request: LoginRequest):
    """
    Login an existing user.
    
    - **email**: User email
    - **password**: User password
    
    Returns access token and user details on success.
    """
    db = get_database()
    
    # Find user by email
    user_doc = db.users.find_one({"email": request.email})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
    # Verify password
    if not verify_password(request.password, user_doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    if not user_doc.get("email_verified", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email before login"
        )
    
    user = User.from_dict(user_doc)
    logger.info(f"User logged in: {request.email}")
    
    # Create access token
    access_token = create_access_token(
        data={"sub": user.id, "email": user.email}
    )
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            onboarding_completed=user.onboarding_completed,
            created_at=user.created_at,
            total_points=user.total_points,
        )
    )


@app.post(
    f"{settings.API_PREFIX}/auth/forgot-password",
    response_model=MessageResponse,
    tags=["Authentication"]
)
async def forgot_password(request: ForgotPasswordRequest):
    """Send password reset code to a registered email."""
    db = get_database()
    user_doc = db.users.find_one({"email": request.email})

    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email not registered"
        )

    try:
        _issue_and_store_password_reset_code(db, user_doc)
    except Exception as e:
        logger.error(f"Failed to send password reset code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send password reset email"
        )

    return MessageResponse(message="Password reset code sent to your email")


@app.post(
    f"{settings.API_PREFIX}/auth/reset-password",
    response_model=MessageResponse,
    tags=["Authentication"]
)
async def reset_password(request: ResetPasswordRequest):
    """Reset user password with a valid reset code."""
    db = get_database()
    user_doc = db.users.find_one({"email": request.email})

    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email not registered"
        )

    stored_hash = user_doc.get("password_reset_code_hash")
    expires_at = user_doc.get("password_reset_expires_at")
    attempts = int(user_doc.get("password_reset_attempts", 0))

    if not stored_hash or not expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset code is not available. Please request a new code."
        )

    if attempts >= settings.PASSWORD_RESET_MAX_ATTEMPTS:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many invalid attempts. Please request a new reset code."
        )

    if datetime.utcnow() > expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset code expired. Please request a new code."
        )

    is_valid = verify_hashed_code(
        email=request.email,
        code=request.code,
        expected_hash=stored_hash,
    )

    if not is_valid:
        db.users.update_one(
            {"_id": user_doc["_id"]},
            {
                "$inc": {"password_reset_attempts": 1},
                "$set": {"updated_at": datetime.utcnow()},
            },
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid reset code"
        )

    db.users.update_one(
        {"_id": user_doc["_id"]},
        {
            "$set": {
                "hashed_password": get_password_hash(request.new_password),
                "password_reset_attempts": 0,
                "updated_at": datetime.utcnow(),
            },
            "$unset": {
                "password_reset_code_hash": "",
                "password_reset_expires_at": "",
            },
        },
    )

    return MessageResponse(message="Password reset successful")


# ======================== Onboarding Endpoint ========================
@app.post(
    f"{settings.API_PREFIX}/onboarding",
    response_model=OnboardingResponse,
    tags=["Onboarding"],
    dependencies=[Depends(get_current_user)]
)
async def update_onboarding(
    request: OnboardingRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Update user's onboarding preferences and schedule.
    Protected endpoint - requires JWT token.
    
    - **daily_focus_goal_minutes**: Daily focus goal (15-480 minutes)
    - **study_time_start**: Study session start time (HH:MM)
    - **study_time_end**: Study session end time (HH:MM)
    - **sleep_time_start**: Sleep time start (HH:MM)
    - **sleep_time_end**: Sleep time end (HH:MM)
    - **institution_time_start**: Institution/work time start (HH:MM)
    - **institution_time_end**: Institution/work time end (HH:MM)
    """
    db = get_database()
    user_id = current_user["user_id"]
    
    # Update user with onboarding data
    update_data = {
        "daily_focus_goal_minutes": request.daily_focus_goal_minutes,
        "study_time_start": request.study_time_start,
        "study_time_end": request.study_time_end,
        "sleep_time_start": request.sleep_time_start,
        "sleep_time_end": request.sleep_time_end,
        "institution_time_start": request.institution_time_start,
        "institution_time_end": request.institution_time_end,
        "onboarding_completed": True,
        "updated_at": datetime.utcnow()
    }
    
    result = db.users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": update_data}
    )
    
    if result.matched_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Fetch updated user
    updated_user_doc = db.users.find_one({"_id": ObjectId(user_id)})
    updated_user = User.from_dict(updated_user_doc)
    
    logger.info(f"User onboarding completed: {user_id}")
    
    return OnboardingResponse(
        message="Onboarding completed successfully",
        user=UserResponse(
            id=updated_user.id,
            email=updated_user.email,
            name=updated_user.name,
            onboarding_completed=updated_user.onboarding_completed,
            created_at=updated_user.created_at,
            total_points=updated_user.total_points,
        )
    )


# ======================== Points and Leaderboard ========================
@app.post(
    f"{settings.API_PREFIX}/stats/events/focus-session",
    response_model=PointEventResponse,
    tags=["Gamification"],
    dependencies=[Depends(get_current_user)]
)
async def log_focus_session_event(
    request: FocusSessionEventRequest,
    current_user: dict = Depends(get_current_user)
):
    db = get_database()
    user_object_id = _to_object_id(current_user["user_id"])
    _ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow()
    start_at = request.started_at or now
    end_at = start_at + timedelta(minutes=request.duration_minutes)
    points_delta = request.duration_minutes

    db.focus_sessions.insert_one({
        "user_id": user_object_id,
        "duration_minutes": request.duration_minutes,
        "points_delta": points_delta,
        "started_at": start_at,
        "ended_at": end_at,
        "created_at": now,
    })

    db.users.update_one(
        {"_id": user_object_id},
        {
            "$inc": {
                "total_points": points_delta,
                "lifetime_focus_minutes": request.duration_minutes,
                "lifetime_focus_sessions": 1,
            },
            "$set": {"updated_at": now},
        }
    )

    user_doc = db.users.find_one({"_id": user_object_id})
    return PointEventResponse(
        message="Focus session points added",
        points_delta=points_delta,
        total_points=int(user_doc.get("total_points", 0)),
    )


@app.post(
    f"{settings.API_PREFIX}/stats/events/block-screen",
    response_model=PointEventResponse,
    tags=["Gamification"],
    dependencies=[Depends(get_current_user)]
)
async def log_block_screen_event(
    request: BlockScreenEventRequest,
    current_user: dict = Depends(get_current_user)
):
    db = get_database()
    user_object_id = _to_object_id(current_user["user_id"])
    _ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow()
    points_delta = -request.points_penalty

    db.block_events.insert_one({
        "user_id": user_object_id,
        "reason": request.reason,
        "package_name": request.package_name,
        "points_delta": points_delta,
        "created_at": now,
    })

    db.users.update_one(
        {"_id": user_object_id},
        {
            "$inc": {
                "total_points": points_delta,
                "lifetime_block_screens": 1,
                "lifetime_points_lost": request.points_penalty,
            },
            "$set": {"updated_at": now},
        }
    )

    user_doc = db.users.find_one({"_id": user_object_id})
    return PointEventResponse(
        message="Block screen penalty applied",
        points_delta=points_delta,
        total_points=int(user_doc.get("total_points", 0)),
    )


@app.get(
    f"{settings.API_PREFIX}/stats/me/today",
    response_model=TodayStatsResponse,
    tags=["Gamification"],
    dependencies=[Depends(get_current_user)]
)
async def get_today_stats(current_user: dict = Depends(get_current_user)):
    db = get_database()
    user_object_id = _to_object_id(current_user["user_id"])
    user_doc = _ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow()
    today_start = datetime.combine(now.date(), time.min)
    tomorrow_start = today_start + timedelta(days=1)
    stats = _aggregate_day_stats(db, user_object_id, today_start, tomorrow_start)

    return TodayStatsResponse(
        date=now.date(),
        total_points=int(user_doc.get("total_points", 0)),
        focus_sessions_count=stats["focus_sessions_count"],
        focus_minutes=stats["focus_minutes"],
        focus_points_gained=stats["focus_points_gained"],
        block_screens_count=stats["block_screens_count"],
        points_lost=stats["points_lost"],
        net_points_today=stats["net_points"],
    )


@app.get(
    f"{settings.API_PREFIX}/stats/me/analytics",
    response_model=AnalyticsResponse,
    tags=["Gamification"],
    dependencies=[Depends(get_current_user)]
)
async def get_analytics(
    days: int = 7,
    current_user: dict = Depends(get_current_user)
):
    if days < 3 or days > 30:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="days must be between 3 and 30"
        )

    db = get_database()
    user_object_id = _to_object_id(current_user["user_id"])
    _ensure_user_points_fields(db, user_object_id)

    now = datetime.utcnow().date()
    start_day = now - timedelta(days=days - 1)
    series_raw = []

    for day_offset in range(days):
        target_day = start_day + timedelta(days=day_offset)
        day_start = datetime.combine(target_day, time.min)
        day_end = day_start + timedelta(days=1)
        day_stats = _aggregate_day_stats(db, user_object_id, day_start, day_end)
        series_raw.append({"date": target_day, **day_stats})

    first_half = series_raw[: max(1, days // 2)]
    second_half = series_raw[max(1, days // 2):]

    first_avg = sum(item["net_points"] for item in first_half) / len(first_half)
    second_avg = sum(item["net_points"] for item in second_half) / len(second_half)

    if second_avg > first_avg + 1:
        trend = "improving"
    elif second_avg < first_avg - 1:
        trend = "declining"
    else:
        trend = "stable"

    return AnalyticsResponse(
        days=days,
        series=[
            AnalyticsDay(
                date=item["date"],
                focus_sessions_count=item["focus_sessions_count"],
                focus_minutes=item["focus_minutes"],
                focus_points_gained=item["focus_points_gained"],
                block_screens_count=item["block_screens_count"],
                points_lost=item["points_lost"],
                net_points=item["net_points"],
            )
            for item in series_raw
        ],
        trend=trend,
        message=_analytics_message(series_raw, trend),
    )


@app.get(
    f"{settings.API_PREFIX}/leaderboard",
    response_model=LeaderboardResponse,
    tags=["Gamification"],
    dependencies=[Depends(get_current_user)]
)
async def get_leaderboard(
    limit: int = 20,
    current_user: dict = Depends(get_current_user)
):
    if limit < 1 or limit > 100:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="limit must be between 1 and 100"
        )

    db = get_database()
    current_user_object_id = _to_object_id(current_user["user_id"])
    current_user_doc = _ensure_user_points_fields(db, current_user_object_id)
    current_points = int(current_user_doc.get("total_points", 0))

    leaderboard_cursor = db.users.find(
        {},
        {"name": 1, "email": 1, "total_points": 1, "created_at": 1}
    ).sort([("total_points", -1), ("created_at", 1)]).limit(limit)

    leaderboard = []
    rank = 1
    for user_doc in leaderboard_cursor:
        leaderboard.append(
            LeaderboardEntry(
                rank=rank,
                user_id=str(user_doc["_id"]),
                name=user_doc.get("name", "Unknown"),
                email=user_doc.get("email", ""),
                total_points=int(user_doc.get("total_points", 0)),
            )
        )
        rank += 1

    better_count = db.users.count_documents({"total_points": {"$gt": current_points}})
    current_user_rank = better_count + 1

    return LeaderboardResponse(
        leaderboard=leaderboard,
        current_user_rank=current_user_rank,
        current_user_points=current_points,
    )


# ======================== Error Handling ========================
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Custom HTTP exception handler."""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """General exception handler."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
