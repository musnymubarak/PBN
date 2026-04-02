"""
Prime Business Network – Auth Pydantic Schemas.
"""

from __future__ import annotations

import re
from typing import Optional

from pydantic import BaseModel, field_validator


# ── Validators ───────────────────────────────────────────────────────────────

_SRI_LANKA_PHONE = re.compile(r"^\+94\d{9}$")


def _validate_phone(v: str) -> str:
    v = v.strip()
    if not _SRI_LANKA_PHONE.match(v):
        raise ValueError("Phone must be in Sri Lanka format: +94XXXXXXXXX")
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
