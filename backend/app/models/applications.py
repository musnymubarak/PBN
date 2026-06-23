"""
Prime Business Network – Application & Status History Models.
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class ApplicationStatus(str, enum.Enum):
    PENDING = "pending"
    FIT_CALL_SCHEDULED = "fit_call_scheduled"
    APPROVED = "approved"
    REJECTED = "rejected"
    WAITLISTED = "waitlisted"


class DecisionAuthority(str, enum.Enum):
    SOLE = "sole"
    SHARED = "shared"
    INFLUENCER = "influencer"


class BusinessLegalType(str, enum.Enum):
    SOLE_PROPRIETORSHIP = "sole_proprietorship"
    PARTNERSHIP = "partnership"
    PVT_LTD = "pvt_ltd"
    PLC = "plc"
    NGO = "ngo"
    OTHER = "other"


class TshirtSize(str, enum.Enum):
    S = "S"
    M = "M"
    L = "L"
    XL = "XL"
    XXL = "XXL"
    XXXL = "XXXL"


class Application(Base, TimestampMixin):
    __tablename__ = "applications"

    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    business_name: Mapped[str] = mapped_column(String(255), nullable=False)
    contact_number: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    district: Mapped[str | None] = mapped_column(String(100), nullable=True)
    industry_category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("industry_categories.id"), nullable=False
    )
    chapter_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("chapters.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[ApplicationStatus] = mapped_column(
        Enum(ApplicationStatus, name="application_status", create_type=True),
        nullable=False,
        default=ApplicationStatus.PENDING,
    )
    fit_call_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # ── Tier 1 profile fields (nullable in DB; frontend-required for new applicants) ──
    designation: Mapped[str | None] = mapped_column(String(100), nullable=True)
    decision_authority: Mapped[DecisionAuthority | None] = mapped_column(
        Enum(
            DecisionAuthority,
            name="decision_authority",
            create_type=False,
            values_callable=lambda x: [e.value for e in x],
        ),
        nullable=True,
    )
    years_in_operation: Mapped[str | None] = mapped_column(String(20), nullable=True)
    business_legal_type: Mapped[BusinessLegalType | None] = mapped_column(
        Enum(
            BusinessLegalType,
            name="business_legal_type",
            create_type=False,
            values_callable=lambda x: [e.value for e in x],
        ),
        nullable=True,
    )
    business_registration_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    website_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    linkedin_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    referred_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    what_you_offer: Mapped[str | None] = mapped_column(String(280), nullable=True)
    what_you_seek: Mapped[str | None] = mapped_column(String(280), nullable=True)

    # ── Onboarding (post-approval) ──
    tshirt_size: Mapped[TshirtSize | None] = mapped_column(
        Enum(
            TshirtSize,
            name="tshirt_size",
            create_type=False,
            values_callable=lambda x: [e.value for e in x],
        ),
        nullable=True,
    )
    onboarding_token: Mapped[str | None] = mapped_column(String(64), nullable=True, unique=True, index=True)
    onboarding_token_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    onboarding_completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    def __repr__(self) -> str:
        return f"<Application {self.full_name} [{self.status.value}]>"


class ApplicationStatusHistory(Base, TimestampMixin):
    __tablename__ = "application_status_history"

    application_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("applications.id", ondelete="CASCADE"), nullable=False, index=True
    )
    old_status: Mapped[str] = mapped_column(String(30), nullable=False)
    new_status: Mapped[str] = mapped_column(String(30), nullable=False)
    changed_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    def __repr__(self) -> str:
        return f"<AppStatusHistory {self.old_status}→{self.new_status}>"
