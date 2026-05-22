"""Admin endpoints for Complements."""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from fastapi.responses import ORJSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.core.response import success_response
from app.features.auth.dependencies import require_role
from app.features.complements import service
from app.features.complements.schemas import (
    ComplementTypeCreate,
    MemberComplementStatusUpdate,
)
from app.models.complements import FulfilmentStatus
from app.models.user import User, UserRole

router = APIRouter(tags=["Complements"])

read_req = require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN, UserRole.CHAPTER_ADMIN])
write_req = require_role([UserRole.SUPER_ADMIN, UserRole.ADMIN])
superadmin_req = require_role([UserRole.SUPER_ADMIN])


@router.get("/admin/complements", summary="List member complements (paginated)")
async def list_endpoint(
    type_code: Optional[str] = Query(None, alias="type"),
    status: Optional[FulfilmentStatus] = Query(None),
    chapter_id: Optional[UUID] = Query(None),
    search: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    current_user: User = Depends(read_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.list_complements(
        db,
        type_code=type_code,
        status=status,
        chapter_id=chapter_id,
        search=search,
        page=page,
        page_size=page_size,
    )
    return success_response(data=result)


@router.patch("/admin/complements/{complement_id}/status", summary="Update fulfilment status")
async def update_status_endpoint(
    complement_id: UUID,
    data: MemberComplementStatusUpdate,
    current_user: User = Depends(write_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.update_status(complement_id, data.status, data.notes, current_user, db)
    return success_response(data=result, message="Status updated")


@router.get("/admin/complement-types", summary="List complement types")
async def list_types_endpoint(
    active_only: bool = Query(True),
    current_user: User = Depends(read_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.list_types(db, active_only=active_only)
    return success_response(data=result)


@router.post("/admin/complement-types", summary="Create a complement type", status_code=201)
async def create_type_endpoint(
    data: ComplementTypeCreate,
    current_user: User = Depends(superadmin_req),
    db: AsyncSession = Depends(get_db),
) -> ORJSONResponse:
    result = await service.create_type(
        data.code, data.name, data.description, data.variants, data.is_active, current_user, db
    )
    return success_response(data=result, status_code=201, message="Complement type created")
