from datetime import datetime
from fastapi import APIRouter, HTTPException, status
from app.database import get_database
from app.schemas import (
    RegisterRequest, RegisterResponse, UserResponse,
    ResendVerificationRequest, MessageResponse,
    VerifyEmailRequest, TokenResponse,
    LoginRequest, ForgotPasswordRequest, ResetPasswordRequest
)
from app.models import User
from app.auth import (
    get_password_hash, verify_password, create_access_token
)
from app.utils.auth_utils import (
    issue_and_store_verification_code,
    issue_and_store_password_reset_code
)
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest):
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
            issue_and_store_verification_code(db, refreshed_user_doc)
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
    
    hashed_password = get_password_hash(request.password)
    user = User(
        email=request.email,
        hashed_password=hashed_password,
        name=request.name,
        email_verified=False,
    )
    user.total_points = 100
    
    # Insert user into database
    result = db.users.insert_one(user.to_dict())
    user.id = str(result.inserted_id)

    inserted_user_doc = db.users.find_one({"_id": result.inserted_id})
    
    try:
        issue_and_store_verification_code(db, inserted_user_doc)
    except Exception as e:
        logger.error(f"Failed to send verification code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send verification email"
        )

    logger.info(f"New user registered (verification pending): {request.email}")

    user_response = UserResponse(
        id=str(result.inserted_id),
        email=user.email,
        name=user.name,
        onboarding_completed=user.onboarding_completed,
        created_at=user.created_at,
        total_points=user.total_points,
    )

    return RegisterResponse(
        message="Verification code sent to your email",
        email=request.email,
        user=user_response,
    )


@router.post("/resend-verification", response_model=MessageResponse)
async def resend_verification(request: ResendVerificationRequest):
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
        issue_and_store_verification_code(db, user_doc)
    except Exception as e:
        logger.error(f"Failed to resend verification code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send verification email"
        )

    return MessageResponse(message="Verification code resent successfully")


@router.post("/verify-email", response_model=TokenResponse)
async def verify_email(request: VerifyEmailRequest):
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
    expires_at = user_doc.get("email_verification_expires_at")
    
    if not stored_hash or not expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code is not available. Please register again."
        )

    if datetime.utcnow() > expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification code expired. Please register again."
        )

    from app.email_service import verify_hashed_code
    is_valid = verify_hashed_code(
        email=request.email,
        code=request.code,
        expected_hash=stored_hash,
    )

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid verification code"
        )

    db.users.update_one(
        {"_id": user_doc["_id"]},
        {
            "$set": {
                "email_verified": True,
                "updated_at": datetime.utcnow(),
            },
            "$unset": {
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


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    db = get_database()
    
    user_doc = db.users.find_one({"email": request.email})
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    
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


@router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(request: ForgotPasswordRequest):
    db = get_database()
    user_doc = db.users.find_one({"email": request.email})

    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email not registered"
        )

    try:
        issue_and_store_password_reset_code(db, user_doc)
    except Exception as e:
        logger.error(f"Failed to send password reset code: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send password reset email"
        )

    return MessageResponse(message="Password reset code sent to your email")


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(request: ResetPasswordRequest):
    db = get_database()
    user_doc = db.users.find_one({"email": request.email})

    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email not registered"
        )

    stored_hash = user_doc.get("password_reset_code_hash")
    expires_at = user_doc.get("password_reset_expires_at")

    if not stored_hash or not expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset code is not available. Please request a new code."
        )

    if datetime.utcnow() > expires_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset code expired. Please request a new code."
        )

    from app.email_service import verify_hashed_code
    is_valid = verify_hashed_code(
        email=request.email,
        code=request.code,
        expected_hash=stored_hash,
    )

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid reset code"
        )

    db.users.update_one(
        {"_id": user_doc["_id"]},
        {
            "$set": {
                "hashed_password": get_password_hash(request.new_password),
                "updated_at": datetime.utcnow(),
            },
            "$unset": {
                "password_reset_code_hash": "",
                "password_reset_expires_at": "",
            },
        },
    )

    return MessageResponse(message="Password reset successful")
