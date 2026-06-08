"""
Prime Business Network – Home Content (dynamic carousel) Router.

Public:
  GET    /home/slides                      -> active, scheduled, targeted slides

Admin (SUPER_ADMIN / ADMIN):
  GET    /admin/home/slides                -> list all (incl. inactive)
  POST   /admin/home/slides                -> create
  PATCH  /admin/home/slides/{slide_id}     -> update
  DELETE /admin/home/slides/{slide_id}     -> delete
  POST   /admin/home/slides/reorder        -> persist a new order
  POST   /admin/home/slides/upload-image   -> upload a banner image
"""

from __future__ import annotations

import logging
import os
import shutil
import uuid
from uuid import UUID

from fastapi import APIRouter, Depends, File, UploadFile
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.exceptions import BadRequestException
from app.core.response import success_response
from app.features.auth.dependencies import get_current_user, require_role
from app.features.home_content import service
from app.features.home_content.schemas import (
    HomeSlideCreate,
    HomeSlideReorder,
    HomeSlideUpdate,
)
from app.models.user import User, UserRole

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Home Content"])

admin_req = require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN])


# ── Public ───────────────────────────────────────────────────────────────────


@router.get("/home/slides", summary="Get active home carousel slides")
async def get_home_slides_endpoint(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    slides = await service.list_public_slides(current_user, db)
    return success_response(data=slides)


# ── Admin: list / create ─────────────────────────────────────────────────────


@router.get("/admin/home/slides", summary="List all home slides (admin)")
async def admin_list_slides_endpoint(
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    return success_response(data=await service.list_admin_slides(db))


@router.post("/admin/home/slides", summary="Create a home slide", status_code=201)
async def admin_create_slide_endpoint(
    data: HomeSlideCreate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    slide = await service.create_slide(data, db)
    return success_response(
        data={"id": str(slide.id)},
        message="Slide created successfully",
        status_code=201,
    )


# ── Admin: reorder (declared before /{slide_id} to keep the static path) ─────


@router.post("/admin/home/slides/reorder", summary="Reorder home slides")
async def admin_reorder_slides_endpoint(
    data: HomeSlideReorder,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await service.reorder_slides(data.ordered_ids, db)
    return success_response(message="Slides reordered successfully")


# ── Admin: upload banner image ───────────────────────────────────────────────


@router.post("/admin/home/slides/upload-image", summary="Upload a banner image")
async def admin_upload_banner_endpoint(
    file: UploadFile = File(...),
    current_user: User = Depends(admin_req),
) -> ORJSONResponse:
    MAX_SIZE = 5 * 1024 * 1024  # 5MB
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException(
            message="File too large. Maximum size allowed is 5MB.",
            code="FILE_TOO_LARGE",
        )

    ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]
    if file.content_type not in ALLOWED_TYPES:
        raise BadRequestException(
            message=f"Invalid file format: {file.content_type}. Only JPEG, PNG, and WebP images are allowed.",
            code="INVALID_FORMAT",
        )

    os.makedirs("uploads/banners", exist_ok=True)
    ext = file.filename.split(".")[-1].lower() if file.filename and "." in file.filename else "jpg"
    if ext not in ["jpg", "jpeg", "png", "webp"]:
        raise BadRequestException(message="Invalid file extension.", code="INVALID_EXTENSION")

    filename = f"banner_{uuid.uuid4().hex[:8]}.{ext}"
    file_path = f"uploads/banners/{filename}"
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return success_response(
        data={"image_url": f"/static/banners/{filename}"},
        message="Image uploaded successfully",
    )


# ── Admin: update / delete ───────────────────────────────────────────────────


@router.patch("/admin/home/slides/{slide_id}", summary="Update a home slide")
async def admin_update_slide_endpoint(
    slide_id: UUID,
    data: HomeSlideUpdate,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    slide = await service.update_slide(slide_id, data, db)
    return success_response(data={"id": str(slide.id)}, message="Slide updated successfully")


@router.delete("/admin/home/slides/{slide_id}", summary="Delete a home slide")
async def admin_delete_slide_endpoint(
    slide_id: UUID,
    current_user: User = Depends(admin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    await service.delete_slide(slide_id, db)
    return success_response(message="Slide deleted successfully")
