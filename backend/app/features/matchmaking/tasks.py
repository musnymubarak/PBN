import uuid
import logging
from typing import List, Dict, Any

from sqlalchemy import select
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session_factory
from app.models.community import CommunityPost
from app.models.marketplace import MarketplaceListing
from app.models.user import User
from app.features.matchmaking.service import MatchmakingService
from app.features.notifications.service import send_push_notification

logger = logging.getLogger(__name__)

async def process_new_opportunity_post(post_id: uuid.UUID):
    """
    Background task to find top matches for a new Lead/RFP post and alert them.
    """
    async with async_session_factory() as db:
        try:
            # 1. Fetch the post and its author
            post = await db.scalar(
                select(CommunityPost)
                .options(joinedload(CommunityPost.author))
                .where(CommunityPost.id == post_id)
            )
            
            if not post or not post.target_industry_id:
                return
                
            # 2. Find members in the target industry (excluding author)
            from app.models.memberships import ChapterMembership
            
            target_members_result = await db.execute(
                select(User)
                .join(ChapterMembership, User.id == ChapterMembership.user_id)
                .where(
                    ChapterMembership.industry_category_id == post.target_industry_id,
                    User.id != post.author_id,
                    User.is_active == True
                )
            )
            target_members = target_members_result.unique().scalars().all()
            
            if not target_members:
                return
                
            # 3. Score them using MatchmakingService
            match_service = MatchmakingService(db)
            scored_matches = []
            
            for target_member in target_members:
                # Get or create matching profiles implicitly via score
                score = await match_service.compute_match_score(post.author_id, target_member.id)
                scored_matches.append((target_member, score.total_score))
                
            # 4. Sort by highest score and take top 5
            scored_matches.sort(key=lambda x: x[1], reverse=True)
            top_matches = scored_matches[:5]
            
            # 5. Send push notifications
            for member, score in top_matches:
                # Check notification settings
                settings = member.notification_settings or {}
                if settings.get("notice_board_matches", True):
                    title = "🎯 New Lead Matches Your Profile!"
                    body = f"{post.author.full_name} is looking for services in your industry."
                    data = {"type": "NOTICE_MATCH", "id": str(post.id)}
                    
                    await send_push_notification(
                        user_id=member.id,
                        title=title,
                        body=body,
                        notification_type="NOTICE_MATCH",
                        data=data
                    )
                    
            logger.info(f"Sent notice_board_matches alerts to {len(top_matches)} members for post {post.id}")
            
        except Exception as e:
            logger.error(f"Error processing new opportunity post {post_id}: {e}", exc_info=True)


async def process_new_marketplace_listing(listing_id: uuid.UUID):
    """
    Background task to find top matches for a new Marketplace Listing and alert them.
    """
    async with async_session_factory() as db:
        try:
            # 1. Fetch the listing and its seller
            listing = await db.scalar(
                select(MarketplaceListing)
                .options(joinedload(MarketplaceListing.seller))
                .where(MarketplaceListing.id == listing_id)
            )
            
            if not listing or not listing.industry_category_id:
                return
                
            # 2. Find members who need this (simplified for MVP: checking if their 'looking_for' matches loosely, or just anyone not the seller)
            # A true implementation would query matching_profiles looking_for arrays, but computing score does this exactly.
            # To avoid computing O(N) scores, let's pre-filter by active users.
            active_users_result = await db.execute(
                select(User).where(User.is_active == True, User.id != listing.seller_id)
            )
            active_users = active_users_result.scalars().all()
            
            if not active_users:
                return
                
            match_service = MatchmakingService(db)
            scored_matches = []
            
            # 3. Compute score between seller and potential buyers
            for buyer in active_users:
                score = await match_service.compute_match_score(listing.seller_id, buyer.id)
                if score.total_score > 0.3: # Only consider decent matches
                    scored_matches.append((buyer, score.total_score))
                    
            # 4. Sort and take top 5
            scored_matches.sort(key=lambda x: x[1], reverse=True)
            top_matches = scored_matches[:5]
            
            # 5. Send push notifications
            for member, score in top_matches:
                settings = member.notification_settings or {}
                if settings.get("deal_opportunity_alerts", True):
                    title = "💼 Deal Alert!"
                    body = f"A new listing '{listing.title}' by {listing.seller.full_name} matches your business needs."
                    data = {"type": "DEAL_ALERT", "id": str(listing.id)}
                    
                    await send_push_notification(
                        user_id=member.id,
                        title=title,
                        body=body,
                        notification_type="DEAL_ALERT",
                        data=data
                    )
                    
            logger.info(f"Sent deal_opportunity_alerts to {len(top_matches)} members for listing {listing.id}")
            
        except Exception as e:
            logger.error(f"Error processing new marketplace listing {listing_id}: {e}", exc_info=True)
