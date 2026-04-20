from __future__ import annotations

import uuid
from typing import Any, Dict, List, Optional
from datetime import datetime, timezone

from sqlalchemy import desc, func, select, delete, exists, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload

from app.core.exceptions import BadRequestException, NotFoundException, ForbiddenException
from app.models.community import CommunityPost, PostLike, PostComment
from app.models.memberships import ChapterMembership
from app.models.user import User, UserRole


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


async def create_post(user_id: uuid.UUID, content: str, image_url: Optional[str], db: AsyncSession) -> Dict[str, Any]:
    chapter_id = await _get_user_chapter_id(user_id, db)
    
    post = CommunityPost(
        chapter_id=chapter_id,
        author_id=user_id,
        content=content,
        image_url=image_url
    )
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
    filter_type: str = "all"
) -> List[Dict[str, Any]]:
    chapter_id = await _get_user_chapter_id(user_id, db)
    # Base query for posts in the chapter
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
    elif filter_type == "pinned":
        stmt = stmt.where(CommunityPost.is_pinned == True)
    
    # Ordering and Pagination
    stmt = (
        stmt.order_by(desc(CommunityPost.is_pinned), desc(CommunityPost.created_at))
        .limit(limit)
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
        "is_liked_by_me": is_liked
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
