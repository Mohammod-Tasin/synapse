from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from bson.objectid import ObjectId
from app.database import get_database
from app.schemas import (
    OnboardingRequest, OnboardingResponse, UserResponse
)
from app.models import User
from app.dependencies import get_current_user
import logging

logger = logging.getLogger(__name__)

# Enforce authentication for ALL onboarding endpoints
router = APIRouter(
    prefix="/onboarding",
    tags=["Onboarding"],
    dependencies=[Depends(get_current_user)]
)

@router.get("", response_model=OnboardingRequest)
async def get_onboarding(current_user: dict = Depends(get_current_user)):
    """Get user's existing onboarding preferences."""
    db = get_database()
    user_id = current_user["user_id"]
    user_doc = db.users.find_one({"_id": ObjectId(user_id)})
    
    if not user_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
        
    return OnboardingRequest(
        daily_focus_goal_minutes=user_doc.get("daily_focus_goal_minutes", 120),
        study_time_start=user_doc.get("study_time_start", "09:00"),
        study_time_end=user_doc.get("study_time_end", "17:00"),
        sleep_time_start=user_doc.get("sleep_time_start", "22:00"),
        sleep_time_end=user_doc.get("sleep_time_end", "07:00"),
        institution_time_start=user_doc.get("institution_time_start", "09:00"),
        institution_time_end=user_doc.get("institution_time_end", "17:00"),
    )

@router.post("", response_model=OnboardingResponse)
async def update_onboarding(
    request: OnboardingRequest,
    current_user: dict = Depends(get_current_user)
):
    """Update user's onboarding preferences."""
    db = get_database()
    user_id = current_user["user_id"]
    
    update_data = {
        "daily_focus_goal_minutes": request.daily_focus_goal_minutes,
        "study_time_start": request.study_time_start,
        "study_time_end": request.study_time_end,
        "sleep_time_start": request.sleep_time_start,
        "sleep_time_end": request.sleep_time_end,
        "institution_time_start": request.institution_time_start,
        "institution_time_end": request.institution_time_end,
        "onboarding_completed": True,
        "updated_at": datetime.now(timezone.utc)
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
