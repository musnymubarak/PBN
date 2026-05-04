import uuid
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.features.auth.dependencies import get_current_user
from app.core.response import success_response
from app.models.user import User
from app.schemas.matchmaking import MatchingProfile, MatchingProfileUpdate, MatchSuggestion
from app.features.matchmaking.service import MatchmakingService

router = APIRouter()

@router.get("/profile")
async def get_my_matching_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get the current user's business matching profile."""
    service = MatchmakingService(db)
    profile = await service.get_or_create_profile(current_user.id)
    return success_response(data=MatchingProfile.model_validate(profile).model_dump(mode='json'))

@router.put("/profile")
async def update_my_matching_profile(
    data: MatchingProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update the current user's business matching profile."""
    service = MatchmakingService(db)
    profile = await service.update_profile(current_user.id, data.model_dump(exclude_unset=True))
    return success_response(data=MatchingProfile.model_validate(profile).model_dump(mode='json'))

@router.post("/compute")
async def compute_my_matches(
    limit: int = Query(10, gt=0, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Trigger re-computation of matches for the current user."""
    service = MatchmakingService(db)
    matches = await service.compute_matches_for_user(current_user.id, limit=limit)
    return success_response(data=[MatchSuggestion.model_validate(m).model_dump(mode='json') for m in matches])

@router.get("/suggestions")
async def get_match_suggestions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get pre-computed match suggestions for the current user."""
    from app.models.matchmaking import MatchSuggestion as MatchSuggestionModel
    from sqlalchemy import select, and_
    from sqlalchemy.orm import joinedload
    
    # We join with User and IndustryCategory to provide a complete summary
    from app.models.memberships import ChapterMembership
    from app.models.industry_categories import IndustryCategory
    
    query = (
        select(MatchSuggestionModel)
        .options(joinedload(MatchSuggestionModel.matched_user))
        .where(
            and_(
                MatchSuggestionModel.user_id == current_user.id,
                MatchSuggestionModel.status != "dismissed"
            )
        )
        .order_by(MatchSuggestionModel.score.desc())
    )
    
    result = await db.execute(query)
    suggestions = result.unique().scalars().all()
    
    # Enrich with industry names
    enriched = []
    for s in suggestions:
        # Get industry name for matched user
        ind_query = (
            select(IndustryCategory.name)
            .join(ChapterMembership, IndustryCategory.id == ChapterMembership.industry_category_id)
            .where(ChapterMembership.user_id == s.matched_user_id)
        )
        result = await db.execute(ind_query)
        ind_name = result.unique().scalar_one_or_none()
        
        # Manual mapping to schema because of extra fields
        item = MatchSuggestion.model_validate(s)
        item.matched_user_name = s.matched_user.full_name
        item.matched_user_photo = s.matched_user.profile_photo
        item.matched_user_industry = ind_name
        enriched.append(item.model_dump(mode='json'))
        
    return success_response(data=enriched)

@router.post("/suggestions/{match_id}/strategy")
async def get_ai_strategy(
    match_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate or retrieve Gemini-powered partnership strategy for a match."""
    service = MatchmakingService(db)
    strategy = await service.get_partnership_strategy(match_id)
    return success_response(data={"strategy": strategy})

@router.post("/suggestions/{match_id}/status")
async def update_match_status(
    match_id: uuid.UUID,
    status: str = Query(..., regex="^(accepted|dismissed|viewed)$"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update status of a match suggestion (e.g., dismiss it)."""
    from app.models.matchmaking import MatchSuggestion as MatchSuggestionModel
    from sqlalchemy import select, and_
    
    result = await db.execute(
        select(MatchSuggestionModel).where(
            and_(
                MatchSuggestionModel.id == match_id,
                MatchSuggestionModel.user_id == current_user.id
            )
        )
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match suggestion not found")
        
    match.status = status
    await db.commit()
    return success_response(data={"status": "updated"})
