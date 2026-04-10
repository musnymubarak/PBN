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
