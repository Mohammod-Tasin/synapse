"""
Configuration module for the FastAPI backend.
Handles environment variables and app settings.
"""
from pydantic_settings import BaseSettings
from datetime import timedelta


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # MongoDB Configuration
    MONGODB_URL: str = "mongodb://localhost:27017"
    DATABASE_NAME: str = "no_to_distraction_db"
    
    # JWT Configuration
    JWT_SECRET_KEY: str = "your-super-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 86400
    
    # API Configuration
    API_TITLE: str = "No To Distraction API"
    API_VERSION: str = "1.0.0"
    API_PREFIX: str = "/api/v1"
    ALLOWED_ORIGINS: list = ["*"]  # Restrict in production

    # Email Verification Configuration
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 465
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_EMAIL: str = ""
    SMTP_USE_SSL: bool = True
    EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES: int = 10
    EMAIL_VERIFICATION_MAX_ATTEMPTS: int = 5
    EMAIL_VERIFICATION_CODE_SECRET: str = ""
    PASSWORD_RESET_CODE_EXPIRE_MINUTES: int = 10
    PASSWORD_RESET_MAX_ATTEMPTS: int = 5
    
    # Password Requirements
    MIN_PASSWORD_LENGTH: int = 8
    
    class Config:
        env_file = ".env"


settings = Settings()
