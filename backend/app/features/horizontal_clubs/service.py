from uuid import UUID
from typing import List, Dict, Any
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.horizontal_clubs import HorizontalClub, HorizontalClubMembership
from app.models.memberships import ChapterMembership
from app.models.industry_categories import IndustryCategory
from app.core.exceptions import BadRequestException

async def list_clubs(user_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    # Get user's industries
    industry_stmt = (
        select(IndustryCategory.name)
        .join(ChapterMembership, ChapterMembership.industry_category_id == IndustryCategory.id)
        .where(ChapterMembership.user_id == user_id, ChapterMembership.is_active == True)
    )
    user_industries = (await db.execute(industry_stmt)).scalars().all()

    # Get all active clubs
    stmt = select(HorizontalClub).where(HorizontalClub.is_active == True)
    result = await db.execute(stmt)
    clubs = result.scalars().all()
    
    # Get user's memberships
    mem_stmt = select(HorizontalClubMembership.club_id).where(HorizontalClubMembership.user_id == user_id)
    mem_result = await db.execute(mem_stmt)
    my_club_ids = set(mem_result.scalars().all())
    
    output = []
    for club in clubs:
        is_eligible = any(club.target_vertical.lower() in ind.lower() or ind.lower() in club.target_vertical.lower() for ind in user_industries)
        output.append({
            "id": str(club.id),
            "name": club.name,
            "description": club.description,
            "target_vertical": club.target_vertical,
            "min_members": club.min_members,
            "is_active": club.is_active,
            "is_member": club.id in my_club_ids,
            "is_eligible": is_eligible
        })
    return output

async def join_club(user_id: UUID, club_id: UUID, db: AsyncSession):
    # 1. Fetch Club Info
    club_stmt = select(HorizontalClub).where(HorizontalClub.id == club_id)
    club = (await db.execute(club_stmt)).scalar_one_or_none()
    if not club:
        raise BadRequestException("Club not found")

    # 2. Check if already a member
    stmt = select(HorizontalClubMembership).where(
        and_(HorizontalClubMembership.user_id == user_id, HorizontalClubMembership.club_id == club_id)
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        return

    # 3. Validate Industry Vertical (Bylaws Art. 6.1)
    # Get user's industries from their chapter memberships
    industry_stmt = (
        select(IndustryCategory.name)
        .join(ChapterMembership, ChapterMembership.industry_category_id == IndustryCategory.id)
        .where(ChapterMembership.user_id == user_id, ChapterMembership.is_active == True)
    )
    user_industries = (await db.execute(industry_stmt)).scalars().all()
    
    # We check if the club's target_vertical matches any of the user's industries
    # Note: Using case-insensitive partial match or exact match depending on data cleanliness
    match_found = any(club.target_vertical.lower() in ind.lower() or ind.lower() in club.target_vertical.lower() for ind in user_industries)
    
    if not match_found:
        raise BadRequestException(
            f"You cannot join this club. Your industry ({', '.join(user_industries)}) does not match the club vertical ({club.target_vertical})."
        )
        
    membership = HorizontalClubMembership(user_id=user_id, club_id=club_id)
    db.add(membership)
    await db.commit()

async def leave_club(user_id: UUID, club_id: UUID, db: AsyncSession):
    stmt = select(HorizontalClubMembership).where(
        and_(HorizontalClubMembership.user_id == user_id, HorizontalClubMembership.club_id == club_id)
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        await db.delete(existing)
        await db.commit()
