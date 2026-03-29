from datetime import datetime, timedelta
from app.config import settings
from app.auth import hash_verification_code
from app.email_service import (
    generate_verification_code,
    send_password_reset_code,
    send_verification_code,
)

def issue_and_store_verification_code(db, user_doc: dict) -> None:
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


def issue_and_store_password_reset_code(db, user_doc: dict) -> None:
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
