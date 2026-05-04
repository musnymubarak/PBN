from __future__ import annotations

import uuid
from typing import Any, Dict, List, Optional
from datetime import datetime, timezone

from sqlalchemy import desc, func, select, delete, exists, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

from app.core.exceptions import BadRequestException, NotFoundException, ForbiddenException
from app.models.community import CommunityPost, PostLike, PostComment, LeadStatus
from app.models.memberships import ChapterMembership
from app.models.user import User, UserRole
from app.features.notifications.service import send_push_notification
from app.features.auth.verification import update_member_verification
from decimal import Decimal


async def _get_user_chapter_id(user_id: uuid.UUID, db: AsyncSession) -> uuid.UUID:
    """Helper to find which chapter a user belongs to."""
    stmt = select(ChapterMembership.chapter_id).where(
        ChapterMembership.user_id == user_id,
        ChapterMembership.is_active == True
    ).limit(1)
    result = (await db.execute(stmt)).scalar_one_or_none()
    if not result:
        raise ForbiddenException("You must be an active member of a chapter to access the community.")
    return result


async def get_chapter_member_ids(chapter_id: uuid.UUID, db: AsyncSession) -> List[uuid.UUID]:
    """Get all active member IDs for a chapter."""
    stmt = select(ChapterMembership.user_id).where(
        ChapterMembership.chapter_id == chapter_id,
        ChapterMembership.is_active == True
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def create_post(
    user_id: uuid.UUID, 
    content: str, 
    image_url: Optional[str], 
    db: AsyncSession,
    post_type: str = "general",
    visibility: str = "chapter",
    budget_range: Optional[str] = None,
    deadline: Optional[datetime] = None,
    target_club_id: Optional[uuid.UUID] = None,
    target_industry_id: Optional[uuid.UUID] = None
) -> Dict[str, Any]:
    chapter_id = await _get_user_chapter_id(user_id, db)
    
    from app.models.community import PostType, PostVisibility, LeadStatus
    
    post = CommunityPost(
        chapter_id=chapter_id,
        author_id=user_id,
        content=content,
        image_url=image_url,
        post_type=PostType(post_type),
        visibility=PostVisibility(visibility),
        budget_range=budget_range,
        deadline=deadline,
        target_club_id=target_club_id,
        target_industry_id=target_industry_id
    )
    
    # Auto-set status for business opportunities
    if post.post_type != PostType.GENERAL:
        post.lead_status = LeadStatus.OPEN
        
    db.add(post)
    await db.commit()
    await db.refresh(post)
    
    # Reload with author for notification info
    stmt = select(CommunityPost).where(CommunityPost.id == post.id).options(joinedload(CommunityPost.author))
    post = (await db.execute(stmt)).scalar_one()
    
    serialized = await _serialize_post(post, user_id, db)
    return {
        "post": serialized,
        "chapter_id": chapter_id,
        "author_name": post.author.full_name
    }


async def list_posts(
    user_id: uuid.UUID, 
    db: AsyncSession, 
    limit: int = 20, 
    offset: int = 0,
    search: Optional[str] = None,
    filter_type: str = "all",
    network_wide: bool = False
) -> List[Dict[str, Any]]:
    chapter_id = await _get_user_chapter_id(user_id, db)
    
    from app.models.community import PostType, PostVisibility
    
    # Base query
    if network_wide:
        # Global feed: Only show posts with NETWORK visibility
        stmt = (
            select(CommunityPost)
            .join(CommunityPost.author)
            .where(CommunityPost.visibility == PostVisibility.NETWORK, CommunityPost.is_active == True)
        )
    else:
        # Chapter feed: Show posts in the chapter
        stmt = (
            select(CommunityPost)
            .join(CommunityPost.author)
            .where(CommunityPost.chapter_id == chapter_id, CommunityPost.is_active == True)
        )

    # 1. Search filter (content OR user name)
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(or_(
            CommunityPost.content.ilike(pattern),
            User.full_name.ilike(pattern)
        ))

    # 2. Category filters
    if filter_type == "my_posts":
        stmt = stmt.where(CommunityPost.author_id == user_id)
    elif filter_type == "pinned" and not network_wide:
        stmt = stmt.where(CommunityPost.is_pinned == True)
    elif filter_type == "lead":
        stmt = stmt.where(CommunityPost.post_type == PostType.LEAD)
    elif filter_type == "rfp":
        stmt = stmt.where(CommunityPost.post_type == PostType.RFP)
    
    # Ordering and Pagination
    # For network feed, we don't prioritize pins from other chapters
    if network_wide:
        stmt = stmt.order_by(desc(CommunityPost.created_at))
    else:
        stmt = stmt.order_by(desc(CommunityPost.is_pinned), desc(CommunityPost.created_at))
        
    stmt = (
        stmt.limit(limit)
        .offset(offset)
        .options(joinedload(CommunityPost.author))
    )
    
    posts = (await db.execute(stmt)).scalars().all()
    
    results = []
    for post in posts:
        results.append(await _serialize_post(post, user_id, db))
    
    return results


async def _serialize_post(post: CommunityPost, viewer_id: uuid.UUID, db: AsyncSession) -> Dict[str, Any]:
    # Counts
    likes_count = (await db.execute(select(func.count(PostLike.id)).where(PostLike.post_id == post.id))).scalar_one()
    comments_count = (await db.execute(select(func.count(PostComment.id)).where(PostComment.post_id == post.id))).scalar_one()
    
    # Liked by me?
    is_liked = (await db.execute(
        select(exists().where(PostLike.post_id == post.id, PostLike.user_id == viewer_id))
    )).scalar_one()
    
    return {
        "id": str(post.id),
        "chapter_id": str(post.chapter_id),
        "content": post.content,
        "image_url": post.image_url,
        "is_pinned": post.is_pinned,
        "created_at": post.created_at.isoformat(),
        "author": {
            "id": str(post.author.id),
            "full_name": post.author.full_name,
            "profile_photo": post.author.profile_photo,
            "role": post.author.role.value
        },
        "likes_count": likes_count,
        "comments_count": comments_count,
        "is_liked_by_me": is_liked,
        "post_type": post.post_type.value,
        "visibility": post.visibility.value,
        "lead_status": post.lead_status.value if post.lead_status else None,
        "budget_range": post.budget_range,
        "deadline": post.deadline.isoformat() if post.deadline else None,
        "target_club_id": str(post.target_club_id) if post.target_club_id else None,
        "target_club_name": post.target_club.name if post.target_club else None,
        "target_industry_id": str(post.target_industry_id) if post.target_industry_id else None,
        "target_industry_name": post.target_industry.name if post.target_industry else None,
        "business_value": float(post.business_value) if post.business_value else None
    }


async def toggle_like(user_id: uuid.UUID, post_id: uuid.UUID, db: AsyncSession) -> Dict[str, Any]:
    # Check if post exists
    post = (await db.execute(select(CommunityPost).where(CommunityPost.id == post_id))).scalar_one_or_none()
    if not post:
        raise NotFoundException("Post not found")
        
    # Check if already liked
    like_stmt = select(PostLike).where(PostLike.post_id == post_id, PostLike.user_id == user_id)
    existing_like = (await db.execute(like_stmt)).scalar_one_or_none()
    
    if existing_like:
        await db.delete(existing_like)
        is_liked = False
    else:
        new_like = PostLike(post_id=post_id, user_id=user_id)
        db.add(new_like)
        is_liked = True
        
    await db.commit()
    
    # Return new count and info for notifications
    count = (await db.execute(select(func.count(PostLike.id)).where(PostLike.post_id == post_id))).scalar_one()
    
    # Get post author and liker name if liked
    liker_name = ""
    if is_liked:
        liker = (await db.execute(select(User.full_name).where(User.id == user_id))).scalar_one()
        liker_name = liker

    return {
        "likes_count": count, 
        "is_liked": is_liked,
        "post_author_id": post.author_id,
        "liker_name": liker_name,
        "post_content": post.content[:50] + "..." if len(post.content) > 50 else post.content
    }


async def add_comment(user_id: uuid.UUID, post_id: uuid.UUID, content: str, db: AsyncSession) -> Dict[str, Any]:
    post = (await db.execute(select(CommunityPost).where(CommunityPost.id == post_id))).scalar_one_or_none()
    if not post:
        raise NotFoundException("Post not found")
        
    comment = PostComment(
        post_id=post_id,
        author_id=user_id,
        content=content
    )
    db.add(comment)
    await db.commit()
    await db.refresh(comment)
    
    # Reload with author for serialization
    stmt = select(PostComment).where(PostComment.id == comment.id).options(joinedload(PostComment.author))
    comment = (await db.execute(stmt)).scalar_one()
    
    return {
        "comment": _serialize_comment(comment),
        "post_author_id": post.author_id,
        "commenter_name": comment.author.full_name,
        "comment_content": comment.content[:50] + "..." if len(comment.content) > 50 else comment.content
    }


async def list_comments(post_id: uuid.UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    stmt = (
        select(PostComment)
        .where(PostComment.post_id == post_id)
        .order_by(PostComment.created_at.asc())
        .options(joinedload(PostComment.author))
    )
    comments = (await db.execute(stmt)).scalars().all()
    return [_serialize_comment(c) for c in comments]


def _serialize_comment(c: PostComment) -> Dict[str, Any]:
    return {
        "id": str(c.id),
        "post_id": str(c.post_id),
        "content": c.content,
        "created_at": c.created_at.isoformat(),
        "author": {
            "id": str(c.author.id),
            "full_name": c.author.full_name,
            "profile_photo": c.author.profile_photo,
            "role": c.author.role.value
        }
    }


async def delete_post(user_id: uuid.UUID, post_id: uuid.UUID, role: UserRole, db: AsyncSession) -> None:
    post = (await db.execute(select(CommunityPost).where(CommunityPost.id == post_id))).scalar_one_or_none()
    if not post:
        raise NotFoundException("Post not found")
        
    # Only author or Admin can delete
    if post.author_id != user_id and role not in [UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN]:
        raise ForbiddenException("You cannot delete this post")
        
    await db.delete(post)
    await db.commit()


async def delete_comment(user_id: uuid.UUID, comment_id: uuid.UUID, role: UserRole, db: AsyncSession) -> None:
    comment = (await db.execute(select(PostComment).where(PostComment.id == comment_id))).scalar_one_or_none()
    if not comment:
        raise NotFoundException("Comment not found")
        
    if comment.author_id != user_id and role not in [UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN]:
        raise ForbiddenException("You cannot delete this comment")
        
    await db.delete(comment)
    await db.commit()


async def toggle_pin(user_id: uuid.UUID, post_id: uuid.UUID, db: AsyncSession) -> Dict[str, Any]:
    # Check if post exists and user is in the same chapter
    user_chapter_id = await _get_user_chapter_id(user_id, db)
    
    post = (await db.execute(select(CommunityPost).where(CommunityPost.id == post_id))).scalar_one_or_none()
    if not post:
        raise NotFoundException("Post not found")
        
    if post.chapter_id != user_chapter_id:
        raise ForbiddenException("You can only pin posts in your own chapter")
        
    post.is_pinned = not post.is_pinned
    await db.commit()
    await db.refresh(post)
    
    return {"id": str(post.id), "is_pinned": post.is_pinned}


async def update_lead_status(user_id: uuid.UUID, post_id: uuid.UUID, status: str, db: AsyncSession) -> None:
    stmt = select(CommunityPost).where(CommunityPost.id == post_id).options(joinedload(CommunityPost.author))
    post = (await db.execute(stmt)).scalar_one_or_none()
    if not post:
        raise NotFoundException("Post not found")
        
    old_status = post.lead_status.value if post.lead_status else "None"
    
    # Author or Admin can update status
    user_stmt = select(User.role).where(User.id == user_id)
    user_role = (await db.execute(user_stmt)).scalar()
    
    if post.author_id != user_id and user_role not in [UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN]:
        raise ForbiddenException("Only the author or an admin can update lead status")
        
    from app.models.community import LeadStatus
    post.lead_status = LeadStatus(status)
    await db.commit()
    
    # Notify author if an admin changed the status
    if post.author_id != user_id:
        try:
            await send_push_notification(
                user_id=post.author_id,
                title="Lead Status Updated",
                body=f"Admin updated your lead '{post.content[:30]}...' to {status}",
                notification_type="LEAD_STATUS_UPDATE",
                data={"post_id": str(post.id), "route": "/community"}
            )
        except Exception:
            pass


async def record_tyfb(user_id: uuid.UUID, post_id: uuid.UUID, business_value: float, db: AsyncSession) -> None:
    """Record business value generated from a post. Usually called by the person who RECEIVED the business."""
    stmt = select(CommunityPost).where(CommunityPost.id == post_id).options(joinedload(CommunityPost.author))
    post = (await db.execute(stmt)).scalar_one_or_none()
    if not post:
        raise NotFoundException("Post not found")
        
    # Get the person thanking (the one recording it)
    thanker_stmt = select(User.full_name).where(User.id == user_id)
    thanker_name = (await db.execute(thanker_stmt)).scalar() or "A member"

    old_value = float(post.business_value) if post.business_value else 0.0
    post.business_value = business_value
    
    from app.models.community import LeadStatus
    post.lead_status = LeadStatus.CLOSED_WON
    await db.commit()
    
    # Attribution & Leveling: The AUTHOR (referrer) gets the credit for generating value
    value_delta = Decimal(str(business_value)) - Decimal(str(old_value))
    if value_delta != 0:
        await update_member_verification(post.author, value_delta, db)
        
    # Notify the Author (The Referrer)
    if post.author_id != user_id:
        try:
            await send_push_notification(
                user_id=post.author_id,
                title="Business Generated! 💰",
                body=f"{thanker_name} recorded {business_value:,.2f} LKR for your lead!",
                notification_type="TYFB_RECEIVED",
                data={"post_id": str(post.id), "route": "/community"}
            )
        except Exception:
            pass
            
    # Notify Chapter Admins of major deal
    if business_value >= 100000:
        try:
            # Find chapter admins
            admin_stmt = select(ChapterMembership.user_id).where(
                ChapterMembership.chapter_id == post.chapter_id,
                ChapterMembership.is_active == True
            ).join(User).where(User.role == UserRole.CHAPTER_ADMIN)
            admin_ids = (await db.execute(admin_stmt)).scalars().all()
            
            from app.features.notifications.service import notify_multiple_users
            await notify_multiple_users(
                admin_ids,
                "Big Deal Alert! 🚀",
                f"A deal worth {business_value:,.2f} LKR was closed in your chapter!",
                "ADMIN_DEAL_ALERT",
                {"post_id": str(post.id)}
            )
        except Exception:
            pass
