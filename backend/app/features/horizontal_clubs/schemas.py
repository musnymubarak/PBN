from pydantic import BaseModel
from uuid import UUID
from typing import Optional

class HorizontalClubResponse(BaseModel):
    id: UUID
    name: str
    description: Optional[str] = None
    target_vertical: str
    min_members: int
    is_active: bool
    is_member: bool = False

    class Config:
        from_attributes = True
