"""
Prime Business Network – Standard API Response Wrapper.

Every endpoint MUST return responses through these helpers so the
contract stays consistent across the entire API surface.

Response format:
{
    "status": "success" | "error",
    "data": <payload> | null,
    "message": null | "error description",
    "code": null | "SNAKE_CASE_ERROR_CODE"
}
"""

from __future__ import annotations

from typing import Any, Generic, Optional, TypeVar

from fastapi.responses import ORJSONResponse
from pydantic import BaseModel

T = TypeVar("T")


# ── Schema ───────────────────────────────────────────────────────────────────


class ApiResponse(BaseModel, Generic[T]):
    """Pydantic schema matching the standard envelope."""

    status: str
    data: Optional[T] = None
    message: Optional[str] = None
    code: Optional[str] = None


# ── Helpers ──────────────────────────────────────────────────────────────────


def success_response(
    data: Any = None,
    message: str | None = None,
    status_code: int = 200,
) -> ORJSONResponse:
    """Return a success envelope."""
    return ORJSONResponse(
        status_code=status_code,
        content={
            "status": "success",
            "data": data,
            "message": message,
            "code": None,
        },
    )


def error_response(
    message: str = "An unexpected error occurred.",
    code: str = "INTERNAL_ERROR",
    status_code: int = 500,
    data: Any = None,
) -> ORJSONResponse:
    """Return an error envelope."""
    return ORJSONResponse(
        status_code=status_code,
        content={
            "status": "error",
            "data": data,
            "message": message,
            "code": code,
        },
    )
