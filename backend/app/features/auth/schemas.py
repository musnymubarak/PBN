"""
Prime Business Network – Auth Pydantic Schemas.
"""

from __future__ import annotations

import re
from typing import Optional

from pydantic import BaseModel, Field, field_validator


# ── Validators ───────────────────────────────────────────────────────────────

_SRI_LANKA_PHONE = re.compile(r"^\+94\d{9}$")


def _validate_phone(v: str) -> str:
    v = v.strip()
    
    # Handle 07XXXXXXXX format
    if re.match(r"^0\d{9}$", v):
        v = "+94" + v[1:]
    
    # Handle 7XXXXXXXX format
    if re.match(r"^\d{9}$", v):
        v = "+94" + v
        
    if not _SRI_LANKA_PHONE.match(v):
        raise ValueError("Phone must be in Sri Lanka format: +94XXXXXXXXX, 07XXXXXXXX or 7XXXXXXXX")
    return v


# ── Request Schemas ──────────────────────────────────────────────────────────


class SendOTPRequest(BaseModel):
    phone_number: str

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return _validate_phone(v)


class VerifyOTPRequest(BaseModel):
    phone_number: str
    otp: str

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return _validate_phone(v)

    @field_validator("otp")
    @classmethod
    def validate_otp(cls, v: str) -> str:
        v = v.strip()
        if not re.match(r"^\d{6}$", v):
            raise ValueError("OTP must be a 6-digit number")
        return v


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LoginRequest(BaseModel):
    """Unified login request for all users (Admin & Members)."""
    identifier: str = Field(..., description="Email or phone number")
    password: str = Field(..., description="User password")


class ForgotPasswordRequest(BaseModel):
    """Request to initiate password reset."""
    identifier: str = Field(..., description="Email or phone number")


class ResetPasswordRequest(BaseModel):
    """Request to complete password reset."""
    identifier: str = Field(..., description="Email or phone number")
    otp: str = Field(..., description="6-digit OTP code")
    new_password: str = Field(..., description="The new password")
    confirm_password: str = Field(..., description="Confirmation of the new password")

    @field_validator("confirm_password")
    @classmethod
    def validate_passwords_match(cls, v: str, info: any) -> str:
        if "new_password" in info.data and v != info.data["new_password"]:
            raise ValueError("Passwords do not match")
        return v


class ChangePasswordRequest(BaseModel):
    """Request for changing user password."""
    current_password: str = Field(..., description="The current password")
    new_password: str = Field(..., description="The new password")
    confirm_password: str = Field(..., description="Confirmation of the new password")

    @field_validator("confirm_password")
    @classmethod
    def validate_passwords_match(cls, v: str, info: any) -> str:
        if "new_password" in info.data and v != info.data["new_password"]:
            raise ValueError("Passwords do not match")
        return v


# ── Response Schemas ─────────────────────────────────────────────────────────


class OTPSentResponse(BaseModel):
    message: str = "OTP sent successfully"


class TokenPairResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserProfileResponse(BaseModel):
    id: str
    phone_number: str
    email: Optional[str] = None
    full_name: str
    role: str
    is_active: bool
    created_at: str
    updated_at: str
