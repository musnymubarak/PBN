from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict


class PostAuthor(BaseModel):
    id: uuid.UUID
    full_name: str
    profile_photo: Optional[str] = None
    role: str

    model_config = ConfigDict(from_attributes=True)


class CommentResponse(BaseModel):
    id: uuid.UUID
    post_id: uuid.UUID
    author: PostAuthor
    content: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PostResponse(BaseModel):
    id: uuid.UUID
    chapter_id: uuid.UUID
    author: PostAuthor
    content: str
    image_url: Optional[str] = None
    is_pinned: bool
    created_at: datetime
    
    likes_count: int = 0
    comments_count: int = 0
    is_liked_by_me: bool = False

    # Economic Engine
    post_type: str = "general"
    visibility: str = "chapter"
    lead_status: Optional[str] = None
    budget_range: Optional[str] = None
    deadline: Optional[datetime] = None
    target_club_id: Optional[uuid.UUID] = None
    target_club_name: Optional[str] = None
    target_industry_id: Optional[uuid.UUID] = None
    target_industry_name: Optional[str] = None
    business_value: Optional[float] = None
    
    model_config = ConfigDict(from_attributes=True)


class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None
    post_type: str = "general"
    visibility: str = "chapter"
    budget_range: Optional[str] = None
    deadline: Optional[datetime] = None
    target_club_id: Optional[uuid.UUID] = None
    target_industry_id: Optional[uuid.UUID] = None


class CommentCreate(BaseModel):
    content: str
