from uuid import UUID
from typing import List
from fastapi import APIRouter, Depends
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import require_role
from app.models.user import User, UserRole
from app.features.horizontal_clubs.service import list_clubs, join_club, leave_club
from app.features.horizontal_clubs.schemas import HorizontalClubResponse

router = APIRouter(tags=["Horizontal Clubs"])

member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])

@router.get("/horizontal-clubs", response_model=List[HorizontalClubResponse])
async def get_clubs(
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db)
):
    clubs = await list_clubs(current_user.id, db)
    return success_response(data=clubs)

@router.post("/horizontal-clubs/{club_id}/join")
async def join_club_endpoint(
    club_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db)
):
    await join_club(current_user.id, club_id, db)
    return success_response(message="Joined club successfully")

@router.post("/horizontal-clubs/{club_id}/leave")
async def leave_club_endpoint(
    club_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db)
):
    await leave_club(current_user.id, club_id, db)
    return success_response(message="Left club successfully")
