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
    
    model_config = ConfigDict(from_attributes=True)


class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None


class CommentCreate(BaseModel):
    content: str
