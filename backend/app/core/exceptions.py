"""
Prime Business Network – Custom Exception Classes.

All business-logic exceptions inherit from `AppException` so they can
be caught by a single global handler in main.py.
"""

from __future__ import annotations

from typing import Any


class AppException(Exception):
    """Base application exception."""

    def __init__(
        self,
        message: str = "An unexpected error occurred.",
        code: str = "INTERNAL_ERROR",
        status_code: int = 500,
        data: Any = None,
    ) -> None:
        self.message = message
        self.code = code
        self.status_code = status_code
        self.data = data
        super().__init__(self.message)


class NotFoundException(AppException):
    def __init__(
        self,
        message: str = "Resource not found.",
        code: str = "NOT_FOUND",
    ) -> None:
        super().__init__(message=message, code=code, status_code=404)


class BadRequestException(AppException):
    def __init__(
        self,
        message: str = "Bad request.",
        code: str = "BAD_REQUEST",
    ) -> None:
        super().__init__(message=message, code=code, status_code=400)


class UnauthorizedException(AppException):
    def __init__(
        self,
        message: str = "Authentication required.",
        code: str = "UNAUTHORIZED",
    ) -> None:
        super().__init__(message=message, code=code, status_code=401)


class ForbiddenException(AppException):
    def __init__(
        self,
        message: str = "Insufficient permissions.",
        code: str = "FORBIDDEN",
    ) -> None:
        super().__init__(message=message, code=code, status_code=403)


class ConflictException(AppException):
    def __init__(
        self,
        message: str = "Resource already exists.",
        code: str = "CONFLICT",
    ) -> None:
        super().__init__(message=message, code=code, status_code=409)


class RateLimitException(AppException):
    def __init__(
        self,
        message: str = "Too many requests. Please try again later.",
        code: str = "RATE_LIMIT_EXCEEDED",
    ) -> None:
        super().__init__(message=message, code=code, status_code=429)
