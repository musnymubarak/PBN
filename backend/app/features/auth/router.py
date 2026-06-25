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
    ForgotPasswordRequest,
    ResetPasswordRequest,
    Verify2FARequest,
    Toggle2FARequest,
    Resend2FARequest,
)
from pydantic import BaseModel

class UpdateProfileRequest(BaseModel):
    full_name: str
    phone_number: str

class UpdateBusinessRequest(BaseModel):
    business_name: str
    description: str | None = None
    website: str | None = None
    address: str | None = None
    established_year: str | None = None
    br_number: str | None = None
    google_maps_url: str | None = None
    linkedin_url: str | None = None
    facebook_url: str | None = None
    instagram_url: str | None = None
from app.features.auth.service import (
    login,
    logout,
    refresh_access_token,
    send_otp,
    verify_otp,
    change_password,
    forgot_password,
    reset_password,
    verify_2fa,
    toggle_2fa,
    resend_2fa,
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
            "must_change_password": current_user.must_change_password,
            "two_factor_enabled": current_user.two_factor_enabled,
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
            "must_change_password": current_user.must_change_password,
            "profile_photo": current_user.profile_photo,
        },
        status_code=200,
    )


@router.delete("/me", summary="Delete current user account")
async def delete_me_endpoint(
    current_user: User = Depends(get_current_user),
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    """Permanently delete the authenticated user's account and data."""
    from app.features.auth.service import delete_account
    await delete_account(current_user, redis, db)
    return success_response(
        data={"message": "Account successfully deleted"},
        status_code=200
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
    from app.features.auth.service import change_password
    await change_password(current_user, body.current_password, body.new_password, db)
    return success_response(
        data={"message": "Password changed successfully"},
        status_code=200
    )


@router.post("/forgot-password", summary="Initiate password reset via email OTP")
async def forgot_password_endpoint(
    body: ForgotPasswordRequest,
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Send an OTP to the user's registered email if found."""
    await forgot_password(body.identifier, redis, db)
    return success_response(message="If an account exists with this identifier, an OTP has been sent to the registered email.")


@router.post("/reset-password", summary="Complete password reset using OTP")
async def reset_password_endpoint(
    body: ResetPasswordRequest,
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Verify OTP and update password."""
    await reset_password(body.identifier, body.otp, body.new_password, redis, db)
    return success_response(message="Password reset successfully. You can now login with your new password.")


@router.post("/verify-2fa", summary="Verify 2FA OTP after login")
async def verify_2fa_endpoint(
    body: Verify2FARequest,
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Complete login by verifying 2FA OTP code."""
    tokens = await verify_2fa(body.tfa_token, body.otp, redis, db)
    return success_response(data=tokens, status_code=200)


@router.post("/resend-2fa", summary="Resend 2FA OTP")
async def resend_2fa_endpoint(
    body: Resend2FARequest,
    redis: Redis = Depends(get_redis),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Resend a new 2FA verification code to user email."""
    await resend_2fa(body.tfa_token, redis, db)
    return success_response(message="A new verification code has been sent to your email.")


@router.put("/2fa", summary="Toggle 2FA on/off")
async def toggle_2fa_endpoint(
    body: Toggle2FARequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    """Enable or disable Two-Factor Authentication."""
    enabled = await toggle_2fa(current_user, body.enable, body.password, db)
    return success_response(
        data={"two_factor_enabled": enabled},
        message=f"Two-Factor Authentication {'enabled' if enabled else 'disabled'}."
    )


@router.get("/me/business", summary="Get current user's business details")
async def get_my_business(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    from app.models.businesses import Business
    from sqlalchemy import select
    stmt = select(Business).where(Business.owner_user_id == current_user.id)
    business = (await db.execute(stmt)).scalar_one_or_none()
    
    if not business:
         return success_response(data=None)
         
    return success_response(data={
        "id": str(business.id),
        "business_name": business.business_name,
        "description": business.description,
        "website": business.website,
        "logo_url": business.logo_url,
        "address": business.address,
        "established_year": business.established_year,
        "br_number": business.br_number,
        "brochure_url": business.brochure_url,
        "google_maps_url": business.google_maps_url,
        "linkedin_url": business.linkedin_url,
        "facebook_url": business.facebook_url,
        "instagram_url": business.instagram_url,
    })


@router.put("/me/business", summary="Update current user's business details")
async def update_my_business(
    body: UpdateBusinessRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    from app.models.businesses import Business
    from sqlalchemy import select
    
    stmt = select(Business).where(Business.owner_user_id == current_user.id)
    business = (await db.execute(stmt)).scalar_one_or_none()
    if not business:
         from app.models.memberships import ChapterMembership
         ind_cat_id = (await db.execute(select(ChapterMembership.industry_category_id).where(ChapterMembership.user_id == current_user.id).limit(1))).scalar_one_or_none()
         if not ind_cat_id:
              from app.models.industry_categories import IndustryCategory
              ind_cat_id = (await db.execute(select(IndustryCategory.id).limit(1))).scalar()
         business = Business(owner_user_id=current_user.id, business_name=body.business_name, industry_category_id=ind_cat_id)
         db.add(business)
         await db.flush()
         
    business.business_name = body.business_name
    business.description = body.description
    business.website = body.website
    business.address = body.address
    business.established_year = body.established_year
    business.br_number = body.br_number
    business.google_maps_url = body.google_maps_url
    business.linkedin_url = body.linkedin_url
    business.facebook_url = body.facebook_url
    business.instagram_url = body.instagram_url
    
    await db.commit()
    return success_response(data={
        "id": str(business.id),
        "business_name": business.business_name,
        "description": business.description,
        "website": business.website,
        "logo_url": business.logo_url,
        "address": business.address,
        "established_year": business.established_year,
        "br_number": business.br_number,
        "brochure_url": business.brochure_url,
        "google_maps_url": business.google_maps_url,
        "linkedin_url": business.linkedin_url,
        "facebook_url": business.facebook_url,
        "instagram_url": business.instagram_url,
    })


@router.post("/me/business/logo", summary="Upload business logo")
async def upload_business_logo(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    from app.core.exceptions import BadRequestException
    from app.models.businesses import Business
    from sqlalchemy import select

    # 1. Size Validation (5MB limit)
    MAX_SIZE = 5 * 1024 * 1024
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException("File too large. Maximum size allowed is 5MB.", code="FILE_TOO_LARGE")

    # 2. Format Validation
    ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]
    if file.content_type not in ALLOWED_TYPES:
        raise BadRequestException("Only JPEG, PNG, and WebP images are allowed.", code="INVALID_FORMAT")

    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "jpg"
    if ext not in ["jpg", "jpeg", "png", "webp"]:
         raise BadRequestException("Invalid file extension.", code="INVALID_EXTENSION")

    os.makedirs("uploads/logos", exist_ok=True)
    filename = f"logo_{current_user.id}_{uuid.uuid4().hex[:8]}.{ext}"
    file_path = f"uploads/logos/{filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Get or create business
    stmt = select(Business).where(Business.owner_user_id == current_user.id)
    business = (await db.execute(stmt)).scalar_one_or_none()
    if not business:
         from app.models.memberships import ChapterMembership
         ind_cat_id = (await db.execute(select(ChapterMembership.industry_category_id).where(ChapterMembership.user_id == current_user.id).limit(1))).scalar_one_or_none()
         if not ind_cat_id:
              from app.models.industry_categories import IndustryCategory
              ind_cat_id = (await db.execute(select(IndustryCategory.id).limit(1))).scalar()
         business = Business(owner_user_id=current_user.id, business_name="My Business", industry_category_id=ind_cat_id)
         db.add(business)
         await db.flush()

    business.logo_url = f"/static/logos/{filename}"
    await db.commit()
    
    return success_response(data={"logo_url": business.logo_url}, status_code=200)


@router.post("/me/business/brochure", summary="Upload business PDF brochure")
async def upload_business_brochure(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> ORJSONResponse:
    from app.core.exceptions import BadRequestException
    from app.models.businesses import Business
    from sqlalchemy import select

    # 1. Size Validation (10MB limit)
    MAX_SIZE = 10 * 1024 * 1024
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException("File too large. Maximum size allowed is 10MB.", code="FILE_TOO_LARGE")

    # 2. Format Validation
    if file.content_type != "application/pdf":
        raise BadRequestException("Only PDF documents are allowed.", code="INVALID_FORMAT")

    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "pdf"
    if ext != "pdf":
         raise BadRequestException("Invalid file extension. Only .pdf is allowed.", code="INVALID_EXTENSION")

    os.makedirs("uploads/brochures", exist_ok=True)
    filename = f"brochure_{current_user.id}_{uuid.uuid4().hex[:8]}.pdf"
    file_path = f"uploads/brochures/{filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Get or create business
    stmt = select(Business).where(Business.owner_user_id == current_user.id)
    business = (await db.execute(stmt)).scalar_one_or_none()
    if not business:
         from app.models.memberships import ChapterMembership
         ind_cat_id = (await db.execute(select(ChapterMembership.industry_category_id).where(ChapterMembership.user_id == current_user.id).limit(1))).scalar_one_or_none()
         if not ind_cat_id:
              from app.models.industry_categories import IndustryCategory
              ind_cat_id = (await db.execute(select(IndustryCategory.id).limit(1))).scalar()
         business = Business(owner_user_id=current_user.id, business_name="My Business", industry_category_id=ind_cat_id)
         db.add(business)
         await db.flush()

    business.brochure_url = f"/static/brochures/{filename}"
    await db.commit()
    
    return success_response(data={"brochure_url": business.brochure_url}, status_code=200)

