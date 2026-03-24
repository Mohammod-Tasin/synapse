"""Email utilities for sending verification codes."""

from email.message import EmailMessage
import hashlib
import hmac
import random
import smtplib

from app.config import settings


def generate_verification_code() -> str:
    """Generate a 6-digit numeric verification code."""
    return f"{random.randint(0, 999999):06d}"


def hash_verification_code(email: str, code: str) -> str:
    """Hash a verification code with email + server secret."""
    secret = settings.EMAIL_VERIFICATION_CODE_SECRET or settings.JWT_SECRET_KEY
    payload = f"{email.lower().strip()}:{code}".encode("utf-8")
    return hmac.new(secret.encode("utf-8"), payload, hashlib.sha256).hexdigest()


def verify_hashed_code(email: str, code: str, expected_hash: str) -> bool:
    """Compare provided code with stored hash using constant-time check."""
    candidate_hash = hash_verification_code(email=email, code=code)
    return hmac.compare_digest(candidate_hash, expected_hash)


def send_verification_code(email: str, code: str) -> None:
    """Send verification code email via SMTP."""
    if not settings.SMTP_USERNAME or not settings.SMTP_PASSWORD:
        raise RuntimeError("SMTP credentials are not configured")

    from_email = settings.SMTP_FROM_EMAIL or settings.SMTP_USERNAME

    message = EmailMessage()
    message["Subject"] = "No To Distraction - Email Verification Code"
    message["From"] = from_email
    message["To"] = email
    message.set_content(
        (
            "Welcome to No To Distraction!\n\n"
            f"Your verification code is: {code}\n\n"
            f"This code will expire in "
            f"{settings.EMAIL_VERIFICATION_CODE_EXPIRE_MINUTES} minutes.\n\n"
            "If you did not request this, please ignore this email."
        )
    )

    if settings.SMTP_USE_SSL:
        with smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT) as smtp:
            smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            smtp.send_message(message)
    else:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as smtp:
            smtp.starttls()
            smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            smtp.send_message(message)


def send_password_reset_code(email: str, code: str) -> None:
    """Send password reset code email via SMTP."""
    if not settings.SMTP_USERNAME or not settings.SMTP_PASSWORD:
        raise RuntimeError("SMTP credentials are not configured")

    from_email = settings.SMTP_FROM_EMAIL or settings.SMTP_USERNAME

    message = EmailMessage()
    message["Subject"] = "No To Distraction - Password Reset Code"
    message["From"] = from_email
    message["To"] = email
    message.set_content(
        (
            "We received a request to reset your password.\n\n"
            f"Your password reset code is: {code}\n\n"
            f"This code will expire in "
            f"{settings.PASSWORD_RESET_CODE_EXPIRE_MINUTES} minutes.\n\n"
            "If you did not request this, please ignore this email."
        )
    )

    if settings.SMTP_USE_SSL:
        with smtplib.SMTP_SSL(settings.SMTP_HOST, settings.SMTP_PORT) as smtp:
            smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            smtp.send_message(message)
    else:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as smtp:
            smtp.starttls()
            smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            smtp.send_message(message)
