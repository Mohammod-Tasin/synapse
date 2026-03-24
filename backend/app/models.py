"""
MongoDB models and schemas using PyMongo.
Defines the User document structure with onboarding data.
"""
from datetime import datetime
from typing import Optional


class User:
    """
    User model representing the MongoDB document structure.
    Stores user authentication and onboarding preferences.
    """
    
    def __init__(
        self,
        email: str,
        hashed_password: str,
        name: str,
        email_verified: bool = False,
        email_verification_code_hash: Optional[str] = None,
        email_verification_expires_at: Optional[datetime] = None,
        email_verification_attempts: int = 0,
        password_reset_code_hash: Optional[str] = None,
        password_reset_expires_at: Optional[datetime] = None,
        password_reset_attempts: int = 0,
        created_at: datetime = None,
        updated_at: datetime = None,
        daily_focus_goal_minutes: Optional[int] = None,
        study_time_start: Optional[str] = None,  # Format: "HH:MM"
        study_time_end: Optional[str] = None,
        sleep_time_start: Optional[str] = None,
        sleep_time_end: Optional[str] = None,
        institution_time_start: Optional[str] = None,
        institution_time_end: Optional[str] = None,
        onboarding_completed: bool = False,
        total_points: int = 0,
        lifetime_focus_minutes: int = 0,
        lifetime_focus_sessions: int = 0,
        lifetime_block_screens: int = 0,
        lifetime_points_lost: int = 0,
        id: Optional[str] = None,
    ):
        self.id = id
        self.email = email
        self.hashed_password = hashed_password
        self.name = name
        self.email_verified = email_verified
        self.email_verification_code_hash = email_verification_code_hash
        self.email_verification_expires_at = email_verification_expires_at
        self.email_verification_attempts = email_verification_attempts
        self.password_reset_code_hash = password_reset_code_hash
        self.password_reset_expires_at = password_reset_expires_at
        self.password_reset_attempts = password_reset_attempts
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()
        
        # Onboarding Fields
        self.daily_focus_goal_minutes = daily_focus_goal_minutes
        self.study_time_start = study_time_start
        self.study_time_end = study_time_end
        self.sleep_time_start = sleep_time_start
        self.sleep_time_end = sleep_time_end
        self.institution_time_start = institution_time_start
        self.institution_time_end = institution_time_end
        self.onboarding_completed = onboarding_completed
        self.total_points = total_points
        self.lifetime_focus_minutes = lifetime_focus_minutes
        self.lifetime_focus_sessions = lifetime_focus_sessions
        self.lifetime_block_screens = lifetime_block_screens
        self.lifetime_points_lost = lifetime_points_lost
    
    def to_dict(self):
        """Convert User instance to dictionary for MongoDB."""
        return {
            "email": self.email,
            "hashed_password": self.hashed_password,
            "name": self.name,
            "email_verified": self.email_verified,
            "email_verification_code_hash": self.email_verification_code_hash,
            "email_verification_expires_at": self.email_verification_expires_at,
            "email_verification_attempts": self.email_verification_attempts,
            "password_reset_code_hash": self.password_reset_code_hash,
            "password_reset_expires_at": self.password_reset_expires_at,
            "password_reset_attempts": self.password_reset_attempts,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "daily_focus_goal_minutes": self.daily_focus_goal_minutes,
            "study_time_start": self.study_time_start,
            "study_time_end": self.study_time_end,
            "sleep_time_start": self.sleep_time_start,
            "sleep_time_end": self.sleep_time_end,
            "institution_time_start": self.institution_time_start,
            "institution_time_end": self.institution_time_end,
            "onboarding_completed": self.onboarding_completed,
            "total_points": self.total_points,
            "lifetime_focus_minutes": self.lifetime_focus_minutes,
            "lifetime_focus_sessions": self.lifetime_focus_sessions,
            "lifetime_block_screens": self.lifetime_block_screens,
            "lifetime_points_lost": self.lifetime_points_lost,
        }
    
    @staticmethod
    def from_dict(data):
        """Create User instance from MongoDB document."""
        return User(
            id=str(data.get("_id")),
            email=data.get("email"),
            hashed_password=data.get("hashed_password"),
            name=data.get("name"),
            email_verified=data.get("email_verified", False),
            email_verification_code_hash=data.get("email_verification_code_hash"),
            email_verification_expires_at=data.get("email_verification_expires_at"),
            email_verification_attempts=data.get("email_verification_attempts", 0),
            password_reset_code_hash=data.get("password_reset_code_hash"),
            password_reset_expires_at=data.get("password_reset_expires_at"),
            password_reset_attempts=data.get("password_reset_attempts", 0),
            created_at=data.get("created_at"),
            updated_at=data.get("updated_at"),
            daily_focus_goal_minutes=data.get("daily_focus_goal_minutes"),
            study_time_start=data.get("study_time_start"),
            study_time_end=data.get("study_time_end"),
            sleep_time_start=data.get("sleep_time_start"),
            sleep_time_end=data.get("sleep_time_end"),
            institution_time_start=data.get("institution_time_start"),
            institution_time_end=data.get("institution_time_end"),
            onboarding_completed=data.get("onboarding_completed", False),
            total_points=data.get("total_points", 0),
            lifetime_focus_minutes=data.get("lifetime_focus_minutes", 0),
            lifetime_focus_sessions=data.get("lifetime_focus_sessions", 0),
            lifetime_block_screens=data.get("lifetime_block_screens", 0),
            lifetime_points_lost=data.get("lifetime_points_lost", 0),
        )
