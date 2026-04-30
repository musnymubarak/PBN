"""
Prime Business Network – User Model.

The User is the core identity entity. Roles control access across the platform.
Verification levels reflect value generated through the ecosystem (Bylaws Article 9).
"""

from __future__ import annotations

import enum
from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, Enum, String, Numeric
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class UserRole(str, enum.Enum):
    """Platform roles – ordered by escalating privileges."""

    PROSPECT = "PROSPECT"
    MEMBER = "MEMBER"
    PARTNER_ADMIN = "PARTNER_ADMIN"
    CHAPTER_ADMIN = "CHAPTER_ADMIN"
    SUPER_ADMIN = "SUPER_ADMIN"


class VerificationLevel(str, enum.Enum):
    """
    Value-Based Membership Verification (Bylaws Article 9.2).

    Tiers based on cumulative verified business value generated
    through the PBN ecosystem within a membership year.
    """
    NONE = "none"
    VERIFIED = "verified"       # LKR 25,000+  — membership investment returned
    SILVER = "silver"           # LKR 1,000,000+
    GOLD = "gold"               # LKR 2,500,000+
    PLATINUM = "platinum"       # LKR 5,000,000+


class User(Base, TimestampMixin):
    """Registered platform user."""

    __tablename__ = "users"

    phone_number: Mapped[str] = mapped_column(
        String(20), unique=True, index=True, nullable=False
    )
    email: Mapped[str | None] = mapped_column(
        String(255), nullable=True, default=None
    )
    full_name: Mapped[str] = mapped_column(
        String(150), nullable=False, default=""
    )
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role", create_type=True),
        nullable=False,
        default=UserRole.PROSPECT,
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True
    )
    fcm_token: Mapped[str | None] = mapped_column(
        String(500), nullable=True, default=None
    )
    password_hash: Mapped[str | None] = mapped_column(
        String(255), nullable=True, default=None
    )
    profile_photo: Mapped[str | None] = mapped_column(
        String(500), nullable=True, default=None
    )
    must_change_password: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False
    )
    notification_settings: Mapped[dict | None] = mapped_column(
        JSONB, nullable=True, default=None
    )

    # ── Value-Based Verification (Bylaws Article 9.2) ────────────────────
    verification_level: Mapped[VerificationLevel] = mapped_column(
        Enum(VerificationLevel, name="verification_level", create_type=True),
        nullable=False,
        default=VerificationLevel.NONE,
    )
    verification_updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
    )
    cumulative_value_generated: Mapped[Decimal] = mapped_column(
        Numeric(precision=16, scale=2), nullable=False, default=Decimal("0.00")
    )

    def __repr__(self) -> str:
        return f"<User {self.phone_number} role={self.role.value} tier={self.verification_level.value}>"
