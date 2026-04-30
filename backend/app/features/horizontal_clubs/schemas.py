from pydantic import BaseModel
from uuid import UUID
from typing import Optional, List

class HorizontalClubResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str] = None
    industries: List[str]
    industry_ids: List[UUID]
    min_members: int
    is_active: bool
    is_member: bool = False
    is_eligible: bool = False

    class Config:
        from_attributes = True
