"""
Prime Business Network – User Model.

The User is the core identity entity. Authentication is phone+OTP only,
no passwords. Roles control access across the platform.
"""

from __future__ import annotations

import enum

from sqlalchemy import Boolean, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class UserRole(str, enum.Enum):
    """Platform roles – ordered by escalating privileges."""

    PROSPECT = "prospect"
    MEMBER = "member"
    CHAPTER_ADMIN = "chapter_admin"
    SUPER_ADMIN = "super_admin"


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

    def __repr__(self) -> str:
        return f"<User {self.phone_number} role={self.role.value}>"
