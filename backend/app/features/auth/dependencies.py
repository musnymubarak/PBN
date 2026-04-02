"""
Prime Business Network – Auth Dependencies.

`get_current_user`  – extracts and validates Bearer token.
`require_role`      – factory that restricts access by role.
"""

from __future__ import annotations

from typing import Callable, List
from uuid import UUID

from fastapi import Depends, Request
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db, get_redis
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.features.auth.service import decode_access_token, get_user_by_id
from app.models.user import User, UserRole


async def get_current_user(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> User:
    """Extract Bearer token, decode it, and return the User record."""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise UnauthorizedException(
            message="Missing or invalid Authorization header.",
            code="MISSING_TOKEN",
        )

    token = auth_header.split(" ", 1)[1]
    payload = decode_access_token(token)

    user_id = payload.get("sub")
    if user_id is None:
        raise UnauthorizedException(
            message="Invalid token payload.", code="INVALID_TOKEN"
        )

    user = await get_user_by_id(UUID(user_id), db)
    if user is None:
        raise UnauthorizedException(
            message="User not found.", code="USER_NOT_FOUND"
        )
    if not user.is_active:
        raise UnauthorizedException(
            message="Account is deactivated.", code="ACCOUNT_INACTIVE"
        )

    return user


def require_role(
    allowed_roles: List[UserRole],
) -> Callable:
    """
    Dependency factory that checks the user's role.

    Usage:
        @router.get("/admin", dependencies=[Depends(require_role([UserRole.SUPER_ADMIN]))])
    Or:
        current_user: User = Depends(require_role([UserRole.MEMBER, UserRole.CHAPTER_ADMIN]))
    """

    async def _role_checker(
        current_user: User = Depends(get_current_user),
    ) -> User:
        if current_user.role not in allowed_roles:
            raise ForbiddenException(
                message=f"Role '{current_user.role.value}' is not permitted for this action.",
                code="INSUFFICIENT_ROLE",
            )
        return current_user

    return _role_checker
