"""
Prime Business Network – Home Content (dynamic carousel) Schemas.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel


class HomeSlideCreate(BaseModel):
    slide_type: str = "custom"
    badge_label: Optional[str] = None
    title: Optional[str] = None
    subtitle: Optional[str] = None
    image_url: Optional[str] = None
    cta_label: Optional[str] = None
    cta_action_type: str = "none"
    cta_action_value: Optional[str] = None
    sort_order: int = 0
    is_active: bool = True
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    audience_roles: Optional[List[str]] = None
    audience_chapter_ids: Optional[List[str]] = None


class HomeSlideUpdate(BaseModel):
    slide_type: Optional[str] = None
    badge_label: Optional[str] = None
    title: Optional[str] = None
    subtitle: Optional[str] = None
    image_url: Optional[str] = None
    cta_label: Optional[str] = None
    cta_action_type: Optional[str] = None
    cta_action_value: Optional[str] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None
    starts_at: Optional[datetime] = None
    ends_at: Optional[datetime] = None
    audience_roles: Optional[List[str]] = None
    audience_chapter_ids: Optional[List[str]] = None


class HomeSlideReorder(BaseModel):
    ordered_ids: List[UUID]
