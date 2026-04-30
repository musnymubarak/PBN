from __future__ import annotations

from uuid import UUID
from typing import List

from fastapi import APIRouter, Depends, Query, BackgroundTasks
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import require_role
from app.features.community.schemas import PostCreate, CommentCreate, PostResponse, CommentResponse
from app.features.community.service import (
    create_post,
    list_posts,
    delete_post,
    toggle_like,
    add_comment,
    list_comments,
    delete_comment,
    get_chapter_member_ids,
    toggle_pin,
    update_lead_status,
    record_tyfb,
)
from app.features.notifications.service import send_push_notification, notify_multiple_users
from app.models.user import User, UserRole

router = APIRouter(tags=["Community"])

# Community available for MEMBERS and above.
member_req = require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN, UserRole.SUPER_ADMIN])

@router.post("/community/posts", summary="Create a new community post", status_code=201)
async def create_post_endpoint(
    data: PostCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await create_post(
        current_user.id, 
        data.content, 
        data.image_url, 
        db,
        post_type=data.post_type,
        visibility=data.visibility,
        budget_range=data.budget_range,
        deadline=data.deadline,
        target_club_id=data.target_club_id,
        target_industry_id=data.target_industry_id
    )
    
    # Notify chapter members
    background_tasks.add_task(
        _notify_new_post,
        result["chapter_id"],
        current_user.id,
        result["author_name"],
        result["post"]["id"]
    )

    return success_response(
        data=result["post"],
        message="Post created successfully",
        status_code=201
    )


async def _notify_new_post(chapter_id: UUID, author_id: UUID, author_name: str, post_id: str):
    # This helper runs as a background task. Use a fresh session.
    from app.core.database import async_session_factory
    async with async_session_factory() as db:
        member_ids = await get_chapter_member_ids(chapter_id, db)
    target_ids = [uid for uid in member_ids if uid != author_id]
    
    if target_ids:
        await notify_multiple_users(
            user_ids=target_ids,
            title="New Chapter Post",
            body=f"{author_name} shared a new update in your chapter.",
            notification_type="community_post",
            data={"post_id": post_id, "type": "community"}
        )


@router.get("/community/posts", summary="Get community feed for user's chapter")
async def list_posts_endpoint(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    search: str = Query(None),
    filter: str = Query("all"),
    network_wide: bool = Query(False),
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    posts = await list_posts(current_user.id, db, limit, offset, search, filter, network_wide)
    return success_response(data=posts)


@router.delete("/community/posts/{post_id}", summary="Delete a community post")
async def delete_post_endpoint(
    post_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await delete_post(current_user.id, post_id, current_user.role, db)
    return success_response(message="Post deleted successfully")


@router.post("/community/posts/{post_id}/like", summary="Toggle like on a post")
async def toggle_like_endpoint(
    post_id: UUID,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await toggle_like(current_user.id, post_id, db)
    
    # Notify author if liked and not self-like
    if result["is_liked"] and result["post_author_id"] != current_user.id:
        background_tasks.add_task(
            send_push_notification,
            user_id=result["post_author_id"],
            title="Post Liked",
            body=f"{result['liker_name']} liked your post: \"{result['post_content']}\"",
            notification_type="community_like",
            data={"post_id": str(post_id), "type": "community"}
        )

    return success_response(data={"likes_count": result["likes_count"], "is_liked": result["is_liked"]}, message="Like toggled")


@router.post("/community/posts/{post_id}/comments", summary="Add a comment to a post", status_code=201)
async def add_comment_endpoint(
    post_id: UUID,
    data: CommentCreate,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await add_comment(current_user.id, post_id, data.content, db)
    
    # Notify author if not self-comment
    if result["post_author_id"] != current_user.id:
        background_tasks.add_task(
            send_push_notification,
            user_id=result["post_author_id"],
            title="New Comment",
            body=f"{result['commenter_name']} commented: \"{result['comment_content']}\"",
            notification_type="community_comment",
            data={"post_id": str(post_id), "type": "community"}
        )

    return success_response(
        data=result["comment"],
        message="Comment added successfully",
        status_code=201
    )


@router.get("/community/posts/{post_id}/comments", summary="List comments for a post")
async def list_comments_endpoint(
    post_id: UUID,
    db: AsyncSession = Depends(get_db),
    # Public within member roles
    current_user: User = Depends(member_req),
) -> ORJSONResponse:
    comments = await list_comments(post_id, db)
    return success_response(data=comments)


@router.delete("/community/comments/{comment_id}", summary="Delete a comment")
async def delete_comment_endpoint(
    comment_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await delete_comment(current_user.id, comment_id, current_user.role, db)
    return success_response(message="Comment deleted successfully")


@router.post("/community/posts/{post_id}/pin", summary="Toggle pin on a post")
async def toggle_pin_endpoint(
    post_id: UUID,
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await toggle_pin(current_user.id, post_id, db)
    return success_response(data=result, message="Pin toggled")


@router.patch("/community/posts/{post_id}/status", summary="Update lead/RFP status")
async def update_lead_status_endpoint(
    post_id: UUID,
    payload: Dict[str, Any],
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    status = payload.get("status")
    if not status:
        return error_response(message="Status is required")
    await update_lead_status(current_user.id, post_id, status, db)
    return success_response(message=f"Lead status updated to {status}")


@router.patch("/community/posts/{post_id}/tyfb", summary="Record TYFB (Thank You For Business) value")
async def record_tyfb_endpoint(
    post_id: UUID,
    payload: Dict[str, Any],
    current_user: User = Depends(member_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    business_value = payload.get("business_value")
    if business_value is None:
        return error_response(message="Business value is required")
    await record_tyfb(current_user.id, post_id, float(business_value), db)
    return success_response(message="TYFB value recorded and lead closed successfully")
