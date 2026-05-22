"""
Prime Business Network – Applications & Industry Categories Schemas.
"""

from __future__ import annotations

from datetime import datetime
from typing import Generic, List, Optional, TypeVar
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from app.features.auth.schemas import _validate_phone
from app.models.applications import (
    ApplicationStatus,
    BusinessLegalType,
    DecisionAuthority,
    TshirtSize,
)

T = TypeVar("T")


# ── Pagination Envelope ──────────────────────────────────────────────────────

class PaginatedResponse(BaseModel, Generic[T]):
    data: List[T]
    total: int
    page: int
    limit: int
    pages: int


# ── Industry Category Schemas ────────────────────────────────────────────────

class IndustryCategoryResponse(BaseModel):
    id: UUID
    name: str
    slug: str
    description: Optional[str] = None
    is_active: bool


# ── Application Schemas ──────────────────────────────────────────────────────

class ApplicationCreate(BaseModel):
    full_name: str
    business_name: str
    contact_number: str
    email: str
    district: Optional[str] = None
    industry_category_id: UUID
    chapter_id: UUID

    # Tier-1 profile fields — all optional on the backend so legacy clients still pass.
    # The public site enforces required-ness (BR remains optional everywhere).
    designation: Optional[str] = Field(None, max_length=100)
    decision_authority: Optional[DecisionAuthority] = None
    years_in_operation: Optional[str] = Field(None, max_length=20)
    business_legal_type: Optional[BusinessLegalType] = None
    business_registration_number: Optional[str] = Field(None, max_length=50)
    website_url: Optional[str] = Field(None, max_length=500)
    linkedin_url: Optional[str] = Field(None, max_length=500)
    referred_by_user_id: Optional[UUID] = None
    what_you_offer: Optional[str] = Field(None, max_length=280)
    what_you_seek: Optional[str] = Field(None, max_length=280)

    @field_validator("contact_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return _validate_phone(v)


class ApplicationResponse(BaseModel):
    id: UUID
    full_name: str
    business_name: str
    contact_number: str
    email: Optional[str] = None
    district: Optional[str] = None
    industry_category_id: UUID
    chapter_id: UUID
    status: ApplicationStatus
    fit_call_date: Optional[datetime] = None
    notes: Optional[str] = None

    designation: Optional[str] = None
    decision_authority: Optional[DecisionAuthority] = None
    years_in_operation: Optional[str] = None
    business_legal_type: Optional[BusinessLegalType] = None
    business_registration_number: Optional[str] = None
    website_url: Optional[str] = None
    linkedin_url: Optional[str] = None
    referred_by_user_id: Optional[UUID] = None
    what_you_offer: Optional[str] = None
    what_you_seek: Optional[str] = None

    tshirt_size: Optional[TshirtSize] = None
    onboarding_completed_at: Optional[datetime] = None

    created_at: datetime
    updated_at: datetime


class ApplicationStatusHistoryResponse(BaseModel):
    id: UUID
    old_status: str
    new_status: str
    notes: Optional[str] = None
    changed_by_user_id: Optional[UUID] = None
    created_at: datetime


class ApplicationDetailResponse(ApplicationResponse):
    history: List[ApplicationStatusHistoryResponse] = Field(default_factory=list)


class ApplicationStatusUpdate(BaseModel):
    status: ApplicationStatus
    notes: Optional[str] = None
    fit_call_date: Optional[datetime] = None
    chapter_id: Optional[UUID] = None  # Needed if approving to assign a chapter
    payment_status: Optional[str] = None  # 'pending' or 'completed'
    email: Optional[str] = None  # Allow admin to backfill missing email when approving


# ── Onboarding Schemas ───────────────────────────────────────────────────────

# Tier-1 fields whose absence should send a legacy applicant to the
# "complete your profile" step. BR is intentionally excluded.
ONBOARDING_REQUIRED_FIELDS: tuple[str, ...] = (
    "designation",
    "decision_authority",
    "years_in_operation",
    "business_legal_type",
    "website_url",
    "linkedin_url",
    "what_you_offer",
    "what_you_seek",
)


class OnboardingStatus(BaseModel):
    """Payload returned from GET /applications/onboard/{token}."""
    application_id: UUID
    full_name: str
    business_name: str
    email: Optional[str] = None
    missing_fields: List[str]
    tshirt_size: Optional[TshirtSize] = None
    completed: bool
    expires_at: datetime

    # Pre-filled values for the missing-fields form so applicants can verify
    # anything they did submit earlier.
    designation: Optional[str] = None
    decision_authority: Optional[DecisionAuthority] = None
    years_in_operation: Optional[str] = None
    business_legal_type: Optional[BusinessLegalType] = None
    business_registration_number: Optional[str] = None
    website_url: Optional[str] = None
    linkedin_url: Optional[str] = None
    what_you_offer: Optional[str] = None
    what_you_seek: Optional[str] = None


class OnboardingDetailsUpdate(BaseModel):
    """PATCH body for filling in missing Tier-1 fields. All keys optional."""
    designation: Optional[str] = Field(None, max_length=100)
    decision_authority: Optional[DecisionAuthority] = None
    years_in_operation: Optional[str] = Field(None, max_length=20)
    business_legal_type: Optional[BusinessLegalType] = None
    business_registration_number: Optional[str] = Field(None, max_length=50)
    website_url: Optional[str] = Field(None, max_length=500)
    linkedin_url: Optional[str] = Field(None, max_length=500)
    what_you_offer: Optional[str] = Field(None, max_length=280)
    what_you_seek: Optional[str] = Field(None, max_length=280)


class OnboardingTshirtUpdate(BaseModel):
    size: TshirtSize
