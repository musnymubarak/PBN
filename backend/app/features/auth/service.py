"""
Prime Business Network – Auth Service.

Handles OTP generation/verification, JWT token creation/validation,
rate limiting, and user creation on first login.
"""

from __future__ import annotations

import hashlib
import logging
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

from jose import JWTError, jwt
from redis.asyncio import Redis
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

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
    """Increment a Redis counter and raise if over the limit."""
    current = await redis.incr(key)
    if current == 1:
        await redis.expire(key, window)
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
    access_token = _create_access_token(user)
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

    new_access = _create_access_token(user)
    return {"access_token": new_access, "token_type": "bearer"}


async def logout(user_id: UUID, redis: Redis) -> None:
    """Revoke the refresh token by deleting it from Redis."""
    refresh_key = REFRESH_KEY.format(user_id=str(user_id))
    await redis.delete(refresh_key)


# ── JWT ──────────────────────────────────────────────────────────────────────


def _create_access_token(user: User) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload = {
        "sub": str(user.id),
        "role": user.role.value,
        "chapter_id": None,  # populated after membership is assigned
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
