"""
Pydantic schemas for request/response validation.
Handles request validation and ensures API contract clarity.
"""
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List
from datetime import datetime, date


class RegisterRequest(BaseModel):
    """Schema for user registration endpoint."""
    email: EmailStr
    password: str
    name: str
    
    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        """Validate password strength."""
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        return v
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v):
        """Validate name field."""
        if len(v.strip()) < 2:
            raise ValueError('Name must be at least 2 characters long')
        return v.strip()


class LoginRequest(BaseModel):
    """Schema for user login endpoint."""
    email: EmailStr
    password: str


class VerifyEmailRequest(BaseModel):
    """Schema for email verification endpoint."""
    email: EmailStr
    code: str

    @field_validator('code')
    @classmethod
    def validate_code(cls, v):
        cleaned = v.strip()
        if len(cleaned) != 6 or not cleaned.isdigit():
            raise ValueError('Verification code must be 6 digits')
        return cleaned


class ResendVerificationRequest(BaseModel):
    """Schema for resending verification code."""
    email: EmailStr


class ForgotPasswordRequest(BaseModel):
    """Schema for forgot password endpoint."""
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Schema for password reset endpoint."""
    email: EmailStr
    code: str
    new_password: str

    @field_validator('code')
    @classmethod
    def validate_reset_code(cls, v):
        cleaned = v.strip()
        if len(cleaned) != 6 or not cleaned.isdigit():
            raise ValueError('Reset code must be 6 digits')
        return cleaned

    @field_validator('new_password')
    @classmethod
    def validate_new_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        if not any(char.isupper() for char in v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not any(char.isdigit() for char in v):
            raise ValueError('Password must contain at least one digit')
        return v


class RegisterResponse(BaseModel):
    """Schema for register response when verification is required."""
    message: str
    email: str


class MessageResponse(BaseModel):
    """Simple message response schema."""
    message: str


class TokenResponse(BaseModel):
    """Schema for token response."""
    access_token: str
    token_type: str
    user: 'UserResponse'


class UserResponse(BaseModel):
    """Schema for user data in response."""
    id: str
    email: str
    name: str
    onboarding_completed: bool
    created_at: datetime
    total_points: int = 0


class OnboardingRequest(BaseModel):
    """Schema for onboarding endpoint."""
    daily_focus_goal_minutes: int
    study_time_start: str  # Format: "HH:MM"
    study_time_end: str
    sleep_time_start: str
    sleep_time_end: str
    institution_time_start: str
    institution_time_end: str
    
    @field_validator('daily_focus_goal_minutes')
    @classmethod
    def validate_focus_goal(cls, v):
        """Validate focus goal minutes."""
        if not (15 <= v <= 960):  # 15 mins to 16 hours
            raise ValueError('Daily focus goal must be between 15 and 960 minutes')
        return v
    
    @field_validator('study_time_start', 'study_time_end', 
                    'sleep_time_start', 'sleep_time_end',
                    'institution_time_start', 'institution_time_end')
    @classmethod
    def validate_time_format(cls, v):
        """Validate time format HH:MM."""
        try:
            parts = v.split(':')
            if len(parts) != 2:
                raise ValueError()
            hour, minute = int(parts[0]), int(parts[1])
            if not (0 <= hour < 24 and 0 <= minute < 60):
                raise ValueError()
        except (ValueError, AttributeError):
            raise ValueError('Time must be in HH:MM format')
        return v


class OnboardingResponse(BaseModel):
    """Schema for onboarding response."""
    message: str
    user: 'UserResponse'


class ErrorResponse(BaseModel):
    """Schema for error responses."""
    detail: str
    status_code: int


class FocusSessionEventRequest(BaseModel):
    """Schema for logging a completed focus session."""
    duration_minutes: int
    started_at: Optional[datetime] = None

    @field_validator('duration_minutes')
    @classmethod
    def validate_duration_minutes(cls, v):
        if not (1 <= v <= 720):
            raise ValueError('duration_minutes must be between 1 and 720')
        return v


class BlockScreenEventRequest(BaseModel):
    """Schema for logging a block screen penalty event."""
    reason: str
    points_penalty: int = 1
    package_name: Optional[str] = None

    @field_validator('reason')
    @classmethod
    def validate_reason(cls, v):
        normalized = v.strip().lower()
        if len(normalized) < 2:
            raise ValueError('reason must be at least 2 characters')
        return normalized

    @field_validator('points_penalty')
    @classmethod
    def validate_points_penalty(cls, v):
        if not (1 <= v <= 50):
            raise ValueError('points_penalty must be between 1 and 50')
        return v


class PointEventResponse(BaseModel):
    """Schema for point mutation event response."""
    message: str
    points_delta: int
    total_points: int


class LeaderboardEntry(BaseModel):
    """Single leaderboard row."""
    rank: int
    user_id: str
    name: str
    email: str
    total_points: int


class LeaderboardResponse(BaseModel):
    """Leaderboard response payload."""
    leaderboard: List[LeaderboardEntry]
    current_user_rank: int
    current_user_points: int


class TodayStatsResponse(BaseModel):
    """Daily summary stats for the authenticated user."""
    date: date
    total_points: int
    focus_sessions_count: int
    focus_minutes: int
    focus_points_gained: int
    block_screens_count: int
    points_lost: int
    net_points_today: int


class AnalyticsDay(BaseModel):
    """One day of analytics series data."""
    date: date
    focus_sessions_count: int
    focus_minutes: int
    focus_points_gained: int
    block_screens_count: int
    points_lost: int
    net_points: int


class AnalyticsResponse(BaseModel):
    """Analytics response payload for a date range."""
    days: int
    series: List[AnalyticsDay]
    trend: str
    message: str
