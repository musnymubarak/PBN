"""
Prime Business Network – Auth Router.

POST /api/v1/auth/send-otp    → generate & store OTP
POST /api/v1/auth/verify-otp  → verify OTP, return tokens
POST /api/v1/auth/refresh     → refresh access token
POST /api/v1/auth/logout      → revoke refresh token
GET  /api/v1/auth/me          → current user profile
"""

from __future__ import annotations

from fastapi import APIRouter, Depends, UploadFile, File
from fastapi.responses import ORJSONResponse
import os
import shutil
import uuid
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_redis
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user
from app.features.auth.schemas import (
    LoginRequest,
    RefreshTokenRequest,
    SendOTPRequest,
    VerifyOTPRequest,
    ChangePasswordRequest,
)
from pydantic import BaseModel

class UpdateProfileRequest(BaseModel):
    full_name: str
    phone_number: str
from app.features.auth.service import (
    login,
    logout,
    refresh_access_token,
    send_otp,
    verify_otp,
    change_password,
)
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["Authentication"])


# ── Unified Login ────────────────────────────────────────────────────────────


@router.post("/login", summary="Login with identifier (email/phone) & password")
async def login_endpoint(
    body: LoginRequest,
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Authenticate any user (Admin/Member) via identifier + password."""
    tokens = await login(body.identifier, body.password, redis, db)
    return success_response(data=tokens, status_code=200)


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
            "profile_photo": current_user.profile_photo,
            "created_at": current_user.created_at.isoformat(),
            "updated_at": current_user.updated_at.isoformat(),
        },
        status_code=200,
    )

@router.put("/me", summary="Update current user profile")
async def update_me_endpoint(
    body: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    """Update the authenticated user's profile."""
    current_user.full_name = body.full_name
    current_user.phone_number = body.phone_number
    await db.commit()
    
    return success_response(
        data={
            "id": str(current_user.id),
            "phone_number": current_user.phone_number,
            "email": current_user.email,
            "full_name": current_user.full_name,
            "role": current_user.role.value,
            "profile_photo": current_user.profile_photo,
        },
        status_code=200,
    )

@router.post("/me/photo", summary="Upload profile photo")
async def upload_profile_photo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    """Upload or update the user's profile photo with validation."""
    from app.core.exceptions import BadRequestException

    # 1. Size Validation (5MB limit)
    MAX_SIZE = 5 * 1024 * 1024
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException(
            message=f"File too large. Maximum size allowed is 5MB. Your file is {file.size / (1024*1024):.1f}MB.",
            code="FILE_TOO_LARGE"
        )

    # 2. Format Validation (MIME type and extension)
    ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]
    if file.content_type not in ALLOWED_TYPES:
        raise BadRequestException(
            message="Invalid file format. Only JPEG, PNG, and WebP images are allowed.",
            code="INVALID_FORMAT"
        )

    os.makedirs("uploads/profiles", exist_ok=True)
    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "jpg"
    
    # Extra check for valid extension string
    if ext not in ["jpg", "jpeg", "png", "webp"]:
         raise BadRequestException(
            message="Invalid file extension. Only .jpg, .jpeg, .png, and .webp are allowed.",
            code="INVALID_EXTENSION"
        )

    filename = f"{current_user.id}_{uuid.uuid4().hex[:8]}.{ext}"
    file_path = f"uploads/profiles/{filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    current_user.profile_photo = f"/static/profiles/{filename}"
    await db.commit()
    
    return success_response(
        data={"profile_photo": current_user.profile_photo},
        status_code=200
    )


@router.put("/change-password", summary="Change current user password")
async def change_password_endpoint(
    body: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    """Verify current password and update to new password for the logged in user."""
    await change_password(current_user, body.current_password, body.new_password, db)
    return success_response(
        data={"message": "Password changed successfully"},
        status_code=200
    )
