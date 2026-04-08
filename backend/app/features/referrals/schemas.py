"""
Prime Business Network – Referrals API Schemas.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel

from app.models.referrals import ReferralStatus


class UserSimple(BaseModel):
    id: UUID
    full_name: str
    phone_number: str
    

class ReferralCreate(BaseModel):
    target_user_id: UUID
    lead_name: str
    lead_contact: str
    lead_email: str # Now required
    description: str # Renamed and required


class ReferralStatusUpdate(BaseModel):
    status: ReferralStatus
    description: Optional[str] = None
    actual_value: Optional[float] = None


class ReferralStatusHistoryResponse(BaseModel):
    id: UUID
    old_status: str
    new_status: str
    notes: Optional[str]
    created_at: datetime


class ReferralResponse(BaseModel):
    id: UUID
    from_user: UserSimple
    target_user: UserSimple
    
    lead_name: str
    lead_contact: str
    lead_email: Optional[str]
    notes: Optional[str]
    
    status: str
    created_at: datetime
    updated_at: datetime
    
    actual_value: Optional[float] = None
    history: Optional[List[ReferralStatusHistoryResponse]] = []
