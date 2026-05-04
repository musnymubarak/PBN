from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, ConfigDict, Field
from app.models.matchmaking import IndustryRelationshipType, MatchSuggestionStatus


class MatchingProfileBase(BaseModel):
    business_description: Optional[str] = None
    services_offered: List[str] = Field(default_factory=list)
    looking_for: List[str] = Field(default_factory=list)
    target_sectors: List[str] = Field(default_factory=list)
    matching_enabled: bool = True
    matching_preferences: Dict[str, Any] = Field(default_factory=dict)


class MatchingProfileCreate(MatchingProfileBase):
    pass


class MatchingProfileUpdate(MatchingProfileBase):
    pass


class MatchingProfile(MatchingProfileBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class MatchSuggestionBase(BaseModel):
    user_id: uuid.UUID
    matched_user_id: uuid.UUID
    score: float
    score_breakdown: Dict[str, float] = Field(default_factory=dict)
    explanation: Optional[str] = None
    partnership_strategy: Optional[str] = None
    status: MatchSuggestionStatus = MatchSuggestionStatus.PENDING
    context: str = "general"


class MatchSuggestion(MatchSuggestionBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    expires_at: Optional[datetime] = None
    
    # Optionally include matched user summary
    matched_user_name: Optional[str] = None
    matched_user_photo: Optional[str] = None
    matched_user_industry: Optional[str] = None


class IndustryRelationshipBase(BaseModel):
    industry_a_id: uuid.UUID
    industry_b_id: uuid.UUID
    relationship_type: IndustryRelationshipType = IndustryRelationshipType.COMPLEMENTARY
    strength: float = 1.0


class IndustryRelationship(IndustryRelationshipBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: uuid.UUID
