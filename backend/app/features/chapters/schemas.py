"""
Prime Business Network – Chapters & Memberships Schemas.
"""

from __future__ import annotations

from datetime import date
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel

from app.models.memberships import MembershipType


class ChapterResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str] = None
    meeting_schedule: Optional[str] = None
    is_active: bool


class IndustryCategorySimple(BaseModel):
    id: UUID
    name: str
    slug: str


class MemberBusinessSimple(BaseModel):
    id: UUID
    business_name: str
    district: Optional[str] = None
    website: Optional[str] = None


class ChapterMemberResponse(BaseModel):
    user_id: UUID
    full_name: str
    email: Optional[str] = None
    phone_number: str
    membership_type: MembershipType
    industry_category: IndustryCategorySimple
    business: Optional[MemberBusinessSimple] = None
    start_date: date
    end_date: Optional[date] = None


class MyMembershipResponse(BaseModel):
    id: UUID
    chapter: ChapterResponse
    industry_category: IndustryCategorySimple
    membership_type: str
    start_date: date
    end_date: Optional[date] = None
    is_active: bool
