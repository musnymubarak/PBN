"""
Prime Business Network – Applications & Industry Categories Schemas.
"""

from __future__ import annotations

from datetime import datetime
from typing import Generic, List, Optional, TypeVar
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from app.features.auth.schemas import _validate_phone
from app.models.applications import ApplicationStatus

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

    @field_validator("contact_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        return _validate_phone(v)


class ApplicationResponse(BaseModel):
    id: UUID
    full_name: str
    business_name: str
    contact_number: str
    email: str
    district: Optional[str] = None
    industry_category_id: UUID
    chapter_id: UUID
    status: ApplicationStatus
    fit_call_date: Optional[datetime] = None
    notes: Optional[str] = None
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
    payment_status: Optional[str] = None # 'pending' or 'completed'
