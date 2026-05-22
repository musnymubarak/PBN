"""Pydantic schemas for the Complements admin endpoints."""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.complements import FulfilmentStatus


class ComplementTypeOut(BaseModel):
    id: UUID
    code: str
    name: str
    description: Optional[str] = None
    variants: Optional[list] = None
    is_active: bool


class ComplementTypeCreate(BaseModel):
    code: str = Field(..., min_length=2, max_length=50)
    name: str = Field(..., min_length=2, max_length=150)
    description: Optional[str] = None
    variants: Optional[list] = None
    is_active: bool = True


class MemberComplementOut(BaseModel):
    id: UUID
    user_id: UUID
    user_full_name: Optional[str] = None
    user_phone_number: Optional[str] = None
    chapter_name: Optional[str] = None

    complement_type_id: UUID
    complement_type_code: str
    complement_type_name: str

    variant: Optional[str] = None
    fulfilment_status: FulfilmentStatus
    assigned_at: datetime
    fulfilled_at: Optional[datetime] = None
    fulfilled_by: Optional[UUID] = None
    notes: Optional[str] = None
    updated_at: datetime


class MemberComplementListResponse(BaseModel):
    items: List[MemberComplementOut]
    total: int
    page: int
    page_size: int


class MemberComplementStatusUpdate(BaseModel):
    status: FulfilmentStatus
    notes: Optional[str] = None
