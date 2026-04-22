"""
Prime Business Network – Auth Service.

Handles OTP generation/verification, JWT token creation/validation,
rate limiting, and user creation on first login.
"""

from __future__ import annotations

import hashlib
import logging
import secrets
import bcrypt

# ── Fix for passlib/bcrypt 4.0 conflict ──────────────────────
if not hasattr(bcrypt, "__about__"):
    bcrypt.__about__ = type("about", (object,), {"__version__": bcrypt.__version__})

from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

from jose import JWTError, jwt
from redis.asyncio import Redis
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from passlib.context import CryptContext

from app.core.config import get_settings
from app.core.exceptions import (
    BadRequestException,
    UnauthorizedException,
    RateLimitException,
)
from app.models.user import User, UserRole

logger = logging.getLogger(__name__)
settings = get_settings()

# ── Redis Key Prefixes ───────────────────────────────────────────────────────

OTP_KEY = "otp:{phone}"
OTP_RATE_KEY = "otp_rate:{phone}"
VERIFY_RATE_KEY = "verify_rate:{phone}"
REFRESH_KEY = "refresh:{user_id}"

# ── Constants ────────────────────────────────────────────────────────────────

OTP_TTL_SECONDS = 300          # 5 minutes
OTP_RATE_LIMIT = 3             # max OTP sends per window
OTP_RATE_WINDOW = 600          # 10 minutes
VERIFY_RATE_LIMIT = 5          # max verify attempts per window
VERIFY_RATE_WINDOW = 900       # 15 minutes


# ── OTP ──────────────────────────────────────────────────────────────────────


def _generate_otp() -> str:
    """Generate a cryptographically random 6-digit OTP."""
    return f"{secrets.randbelow(900000) + 100000}"


def _hash_otp(otp: str) -> str:
    """SHA-256 hash an OTP before storing in Redis."""
    return hashlib.sha256(otp.encode()).hexdigest()


async def _check_rate_limit(
    redis: Redis, key: str, limit: int, window: int, error_msg: str
) -> None:
    """Increment a Redis counter atomically and raise if over the limit."""
    async with redis.pipeline(transaction=True) as pipe:
        await pipe.incr(key)
        await pipe.expire(key, window)
        results = await pipe.execute()
    current = results[0]
    if current > limit:
        raise RateLimitException(message=error_msg, code="RATE_LIMIT_EXCEEDED")


async def send_otp(phone_number: str, redis: Redis) -> None:
    """Generate, hash, store OTP in Redis, and log it (SMS stub)."""

    # Rate limit check
    rate_key = OTP_RATE_KEY.format(phone=phone_number)
    await _check_rate_limit(
        redis, rate_key, OTP_RATE_LIMIT, OTP_RATE_WINDOW,
        "Too many OTP requests. Try again in 10 minutes.",
    )

    otp = _generate_otp()
    hashed = _hash_otp(otp)

    otp_key = OTP_KEY.format(phone=phone_number)
    await redis.set(otp_key, hashed, ex=OTP_TTL_SECONDS)

    # ── SMS stub – replace with real SMS gateway in production ──
    logger.info(
        "📱 [SMS STUB] OTP for %s: %s  (DO NOT log in production!)",
        phone_number, otp,
    )


async def verify_otp(
    phone_number: str,
    otp: str,
    redis: Redis,
    db: AsyncSession,
) -> dict[str, Any]:
    """Verify OTP, create user if first login, return token pair."""

    # Rate limit check
    rate_key = VERIFY_RATE_KEY.format(phone=phone_number)
    await _check_rate_limit(
        redis, rate_key, VERIFY_RATE_LIMIT, VERIFY_RATE_WINDOW,
        "Too many verification attempts. Try again in 15 minutes.",
    )

    # Retrieve stored OTP hash
    otp_key = OTP_KEY.format(phone=phone_number)
    stored_hash = await redis.get(otp_key)

    if stored_hash is None:
        raise BadRequestException(
            message="OTP expired or not requested.", code="OTP_EXPIRED"
        )

    # Compare hashes
    if _hash_otp(otp) != stored_hash:
        raise BadRequestException(
            message="Invalid OTP.", code="INVALID_OTP"
        )

    # OTP valid – delete it (single use)
    await redis.delete(otp_key)

    # Find or create user
    user = await _get_or_create_user(phone_number, db)

    # Generate tokens
    access_token = await create_access_token_with_claims(user, db)
    refresh_token = _create_refresh_token(user)

    # Store refresh token in Redis for invalidation
    refresh_key = REFRESH_KEY.format(user_id=str(user.id))
    await redis.set(
        refresh_key,
        _hash_otp(refresh_token),  # hash before storing
        ex=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400,
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
    }


async def refresh_access_token(
    refresh_token: str,
    redis: Redis,
    db: AsyncSession,
) -> dict[str, Any]:
    """Validate refresh token and issue a new access token."""

    payload = _decode_token(refresh_token, is_refresh=True)
    user_id = payload.get("sub")
    if user_id is None:
        raise UnauthorizedException(message="Invalid refresh token.", code="INVALID_TOKEN")

    # Check token is still in Redis (not logged out)
    refresh_key = REFRESH_KEY.format(user_id=user_id)
    stored_hash = await redis.get(refresh_key)
    if stored_hash is None or stored_hash != _hash_otp(refresh_token):
        raise UnauthorizedException(
            message="Refresh token revoked or expired.", code="TOKEN_REVOKED"
        )

    # Fetch user
    user = await _get_user_by_id(UUID(user_id), db)
    if user is None or not user.is_active:
        raise UnauthorizedException(message="Account deactivated.", code="ACCOUNT_INACTIVE")

    new_access = await create_access_token_with_claims(user, db)
    return {"access_token": new_access, "token_type": "bearer"}


async def logout(user_id: UUID, redis: Redis) -> None:
    """Revoke the refresh token by deleting it from Redis."""
    refresh_key = REFRESH_KEY.format(user_id=str(user_id))
    await redis.delete(refresh_key)


# ── JWT ──────────────────────────────────────────────────────────────────────


async def create_access_token_with_claims(user: User, db: AsyncSession) -> str:
    """Create an access token with chapter_id populated from active membership."""
    from app.models.memberships import ChapterMembership

    stmt = select(ChapterMembership.chapter_id).where(
        ChapterMembership.user_id == user.id,
        ChapterMembership.is_active.is_(True)
    ).limit(1)
    chapter_id = (await db.execute(stmt)).scalar_one_or_none()

    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload = {
        "sub": str(user.id),
        "role": user.role.value,
        "chapter_id": str(chapter_id) if chapter_id else None,
        "type": "access",
        "exp": expire,
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")


def _create_access_token(user: User) -> str:
    """Legacy helper — prefer create_access_token_with_claims."""
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload = {
        "sub": str(user.id),
        "role": user.role.value,
        "chapter_id": None,
        "type": "access",
        "exp": expire,
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")


def _create_refresh_token(user: User) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    payload = {
        "sub": str(user.id),
        "type": "refresh",
        "exp": expire,
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")


def _decode_token(token: str, *, is_refresh: bool = False) -> dict:
    """Decode and validate a JWT. Raises UnauthorizedException on failure."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
    except JWTError:
        raise UnauthorizedException(
            message="Token is invalid or expired.", code="INVALID_TOKEN"
        )

    expected_type = "refresh" if is_refresh else "access"
    if payload.get("type") != expected_type:
        raise UnauthorizedException(
            message=f"Expected {expected_type} token.", code="WRONG_TOKEN_TYPE"
        )

    return payload


def decode_access_token(token: str) -> dict:
    """Public helper – decode an access token."""
    return _decode_token(token, is_refresh=False)


# ── Database Helpers ─────────────────────────────────────────────────────────


async def _get_or_create_user(phone_number: str, db: AsyncSession) -> User:
    """Find existing user by phone or create a new prospect."""
    stmt = select(User).where(User.phone_number == phone_number)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if user is None:
        user = User(
            phone_number=phone_number,
            full_name="",
            role=UserRole.PROSPECT,
            is_active=True,
        )
        db.add(user)
        await db.flush()  # get the id without committing
        logger.info("New user created: %s (prospect)", phone_number)

    return user


async def _get_user_by_id(user_id: UUID, db: AsyncSession) -> User | None:
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_user_by_id(user_id: UUID, db: AsyncSession) -> User | None:
    """Public accessor for other features."""
    return await _get_user_by_id(user_id, db)


# ── Password Hashing ─────────────────────────────────────────────────────────

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

# ── Unified Login ────────────────────────────────────────────────────────────


async def login(
    identifier: str,
    password: str,
    redis: Redis,
    db: AsyncSession,
) -> dict[str, Any]:
    """Authenticate any user (Admin or Member) via identifier (email/phone) + password."""
    print(f"\n🚀 LOGIN ATTEMPT: identifier='{identifier}'")
    logger.info("🔑 Login attempt for identifier: '%s'", identifier)
    # Lookup by phone or email
    query = select(User).where(
        or_(
            User.phone_number == identifier,
            User.email == identifier,
        )
    )
    # Use .first() because multiple users may share the same email
    result = await db.execute(query)
    user = result.scalars().first()

    if not user:
        print(f"❌ LOGIN FAILED: User not found for '{identifier}'")
        logger.warning("❌ Login FAILED: User NOT FOUND for identifier: '%s'", identifier)
        raise UnauthorizedException(
            message="Invalid credentials.", code="INVALID_CREDENTIALS"
        )
    
    print(f"✅ USER FOUND: {user.email} (ID: {user.id})")
    logger.info("✅ User FOUND: %s (id: %s)", user.email or user.phone_number, user.id)

    if not user.is_active:
        raise UnauthorizedException(
            message="Account is deactivated.", code="ACCOUNT_INACTIVE"
        )

    if not user.password_hash:
        raise UnauthorizedException(
            message="Password not configured for this account.",
            code="NO_PASSWORD",
        )

    # Verify password
    try:
        if not pwd_context.verify(password, user.password_hash):
            logger.warning("❌ Login FAILED: Password mismatch for user: %s", user.email or user.id)
            raise UnauthorizedException(
                message="Invalid credentials.", code="INVALID_CREDENTIALS"
            )
        logger.info("✅ Login SUCCESS for user: %s", user.email or user.id)
    except Exception as e:
        logger.error(f"❌ Password verification error: {e}")
        raise UnauthorizedException(
            message="Invalid credentials.", code="INVALID_CREDENTIALS"
        )

    # Generate tokens
    access_token = await create_access_token_with_claims(user, db)
    refresh_token = _create_refresh_token(user)

    # Store refresh token in Redis for invalidation
    refresh_key = REFRESH_KEY.format(user_id=str(user.id))
    await redis.set(
        refresh_key,
        _hash_otp(refresh_token),  # hash before storing
        ex=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400,
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": str(user.id),
            "full_name": user.full_name,
            "email": user.email,
            "role": user.role.value,
            "must_change_password": user.must_change_password,
        },
    }


async def change_password(
    user: User,
    current_password: str,
    new_password: str,
    db: AsyncSession,
) -> None:
    """Verify current password and update to new password."""
    if not user.password_hash:
        raise BadRequestException(
            message="Password not set for this account. Please use OTP login first.",
            code="NO_PASSWORD_SET"
        )

    if not pwd_context.verify(current_password, user.password_hash):
        raise UnauthorizedException(
            message="Incorrect current password.",
            code="INVALID_CURRENT_PASSWORD"
        )

    user.password_hash = hash_password(new_password)
    user.must_change_password = False
    await db.commit()
    logger.info("Password changed for user: %s", user.id)


async def forgot_password(
    identifier: str,
    redis: Redis,
    db: AsyncSession,
) -> None:
    """Initiate password reset by sending OTP to registered email/phone."""
    from app.core.email_service import send_email, render_template
    
    # 1. Find user
    query = select(User).where(
        or_(
            User.phone_number == identifier,
            User.email == identifier,
        )
    )
    result = await db.execute(query)
    user = result.scalars().first()

    if not user:
        # Silently fail to avoid user enumeration
        logger.warning(f"Forgot password requested for unknown user: {identifier}")
        return

    if not user.email:
        logger.warning(f"User {user.id} requested password reset but has no email.")
        # If no email, we could potentially use SMS here if configured
        return

    # 2. Rate limit check (using the same key as phone OTP for consistency)
    rate_key = OTP_RATE_KEY.format(phone=identifier)
    await _check_rate_limit(
        redis, rate_key, OTP_RATE_LIMIT, OTP_RATE_WINDOW,
        "Too many password reset requests. Try again in 10 minutes.",
    )

    # 3. Generate and store OTP
    otp = _generate_otp()
    hashed = _hash_otp(otp)

    otp_key = OTP_KEY.format(phone=identifier)
    await redis.set(otp_key, hashed, ex=OTP_TTL_SECONDS)

    # 4. Send Email
    try:
        html = render_template("otp_email.html", {"otp": otp})
        await send_email(user.email, "PBN Password Recovery", html)
        logger.info(f"Password reset OTP sent to {user.email}")
    except Exception as e:
        logger.error(f"Failed to send password reset email to {user.email}: {e}")
        raise BadRequestException(message="Failed to send reset email. Please try again later.")


async def reset_password(
    identifier: str,
    otp: str,
    new_password: str,
    redis: Redis,
    db: AsyncSession,
) -> None:
    """Verify OTP and update user password."""
    # 1. Verify OTP (identical to verify_otp logic)
    otp_key = OTP_KEY.format(phone=identifier)
    stored_hash = await redis.get(otp_key)

    if stored_hash is None:
        raise BadRequestException(message="OTP expired or not requested.", code="OTP_EXPIRED")

    if _hash_otp(otp) != stored_hash:
        raise BadRequestException(message="Invalid OTP.", code="INVALID_OTP")

    # 2. OTP valid – delete it
    await redis.delete(otp_key)

    # 3. Find user
    query = select(User).where(
        or_(
            User.phone_number == identifier,
            User.email == identifier,
        )
    )
    result = await db.execute(query)
    user = result.scalars().first()

    if not user:
        raise BadRequestException(message="User no longer exists.", code="USER_NOT_FOUND")

    # 4. Update Password
    user.password_hash = hash_password(new_password)
    user.must_change_password = False
    await db.commit()
    logger.info(f"Password reset SUCCESS for user: {user.id}")

