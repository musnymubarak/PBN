"""
Prime Business Network – Auth Router.

POST /api/v1/auth/send-otp    → generate & store OTP
POST /api/v1/auth/verify-otp  → verify OTP, return tokens
POST /api/v1/auth/refresh     → refresh access token
POST /api/v1/auth/logout      → revoke refresh token
GET  /api/v1/auth/me          → current user profile
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from fastapi.responses import ORJSONResponse
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_redis
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user
from app.features.auth.schemas import (
    RefreshTokenRequest,
    SendOTPRequest,
    VerifyOTPRequest,
)
from app.features.auth.service import (
    logout,
    refresh_access_token,
    send_otp,
    verify_otp,
)
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["Authentication"])


# ── Dev-only: retrieve OTP for automated testing ─────────────────────────────

from app.core.config import get_settings as _get_settings
_settings = _get_settings()

if _settings.ENVIRONMENT == "development":
    from app.features.auth.service import OTP_KEY

    @router.get("/dev/otp/{phone_number}", summary="[DEV] Get stored OTP hash", include_in_schema=False)
    async def dev_get_otp(
        phone_number: str,
        redis: Redis = Depends(get_redis),
    ) -> ORJSONResponse:
        """DEV ONLY — Returns the stored OTP hash for automated testing."""
        otp_key = OTP_KEY.format(phone=phone_number)
        stored = await redis.get(otp_key)
        return success_response(data={"otp_hash": stored})


# ── Send OTP ─────────────────────────────────────────────────────────────────


@router.post("/send-otp", summary="Request OTP")
async def send_otp_endpoint(
    body: SendOTPRequest,
    redis: Redis = Depends(get_redis),
) -> ORJSONResponse:
    """Send a 6-digit OTP to the given phone number."""
    await send_otp(body.phone_number, redis)
    return success_response(
        data={"message": "OTP sent successfully"},
        status_code=200,
    )


# ── Verify OTP ───────────────────────────────────────────────────────────────


@router.post("/verify-otp", summary="Verify OTP & get tokens")
async def verify_otp_endpoint(
    body: VerifyOTPRequest,
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Verify the OTP and return access + refresh tokens."""
    tokens = await verify_otp(body.phone_number, body.otp, redis, db)
    return success_response(data=tokens, status_code=200)


# ── Refresh Token ────────────────────────────────────────────────────────────


@router.post("/refresh", summary="Refresh access token")
async def refresh_endpoint(
    body: RefreshTokenRequest,
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Exchange a valid refresh token for a new access token."""
    result = await refresh_access_token(body.refresh_token, redis, db)
    return success_response(data=result, status_code=200)


# ── Logout ───────────────────────────────────────────────────────────────────


@router.post("/logout", summary="Logout (revoke refresh token)")
async def logout_endpoint(
    current_user: User = Depends(get_current_user),
    redis: Redis = Depends(get_redis),
) -> ORJSONResponse:
    """Revoke the refresh token so it can no longer be used."""
    await logout(current_user.id, redis)
    return success_response(
        data={"message": "Logged out successfully"},
        status_code=200,
    )


# ── Me ───────────────────────────────────────────────────────────────────────


@router.get("/me", summary="Get current user profile")
async def me_endpoint(
    current_user: User = Depends(get_current_user),
) -> ORJSONResponse:
    """Return the authenticated user's profile."""
    return success_response(
        data={
            "id": str(current_user.id),
            "phone_number": current_user.phone_number,
            "email": current_user.email,
            "full_name": current_user.full_name,
            "role": current_user.role.value,
            "is_active": current_user.is_active,
            "created_at": current_user.created_at.isoformat(),
            "updated_at": current_user.updated_at.isoformat(),
        },
        status_code=200,
    )
