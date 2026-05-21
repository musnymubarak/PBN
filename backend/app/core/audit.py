"""
Prime Business Network – Audit Middleware & Helpers.

Captures every authenticated mutation that hits a route considered
"admin-panel scope". A row is written to `audit_logs` with the actor,
HTTP context, request body summary (PII-stripped) and status code.

Design notes:
- The middleware runs after FastAPI has built the response, so the user
  request path is NOT delayed by audit-row insert. We schedule the DB
  write via `BackgroundTasks`-style coroutine on the running loop.
- We re-decode the JWT here (cheap) instead of plumbing actor info
  through request.state to keep this fully orthogonal to auth.
- Sensitive fields are scrubbed before persistence.
"""

from __future__ import annotations

import asyncio
import json
import logging
import re
import time
from typing import Any, Iterable
from uuid import UUID

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.database import async_session_factory
from app.models.audit_logs import AuditLog

logger = logging.getLogger(__name__)


# Paths whose mutations we ALWAYS skip — public/auth/health/static.
_SKIP_PATH_PREFIXES: tuple[str, ...] = (
    "/static",
    "/health",
    "/docs",
    "/redoc",
    "/openapi.json",
)

# Auth endpoints we explicitly skip (login/refresh/forgot are NOT admin ops).
_SKIP_AUTH_PATHS: tuple[str, ...] = (
    "/auth/login",
    "/auth/refresh",
    "/auth/send-otp",
    "/auth/verify-otp",
    "/auth/forgot-password",
    "/auth/reset-password",
    "/auth/verify-2fa",
    "/auth/resend-2fa",
    "/auth/logout",
)

# Only POST/PUT/PATCH/DELETE on these route prefixes are recorded.
# We deliberately scope this to admin-panel surface — member-side endpoints
# (e.g. a member creating a referral) are out of scope.
_AUDIT_PATH_PREFIXES: tuple[str, ...] = (
    "/admin",
    "/chapters",
    "/applications",
    "/events",
    "/rewards",
    "/horizontal-clubs",
    "/marketplace",
)

# These admin-panel mutating endpoints live outside /admin/* so we whitelist
# them by exact-suffix match on the request path.
_AUDIT_EXACT_PATHS: tuple[str, ...] = (
    "/auth/me",
    "/auth/me/photo",
    "/auth/2fa",
    "/auth/change-password",
)

_AUDIT_METHODS: frozenset[str] = frozenset({"POST", "PUT", "PATCH", "DELETE"})

_SENSITIVE_KEYS: frozenset[str] = frozenset({
    "password", "password_hash", "current_password", "new_password",
    "old_password", "token", "access_token", "refresh_token",
    "otp", "code", "secret", "api_key", "authorization",
})

# Cap stored body to avoid bloating the audit table on file uploads etc.
_MAX_BODY_BYTES = 8 * 1024

_UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)


# ── Public helpers ──────────────────────────────────────────────────────────


def scrub(value: Any) -> Any:
    """Recursively redact sensitive keys from a nested dict/list."""
    if isinstance(value, dict):
        return {
            k: ("***" if k.lower() in _SENSITIVE_KEYS else scrub(v))
            for k, v in value.items()
        }
    if isinstance(value, list):
        return [scrub(v) for v in value]
    return value


def derive_entity_from_path(path: str) -> tuple[str, UUID | None]:
    """
    Best-effort: split path into entity_type (second meaningful segment)
    and entity_id (last UUID segment if present).
    """
    parts = [p for p in path.split("/") if p and p != "api" and not p.startswith("v")]
    if not parts:
        return "request", None

    entity_type = parts[1] if parts[0] == "admin" and len(parts) > 1 else parts[0]
    entity_type = entity_type.replace("-", "_")[:50]

    entity_id: UUID | None = None
    for seg in reversed(parts):
        if _UUID_RE.match(seg):
            try:
                entity_id = UUID(seg)
            except ValueError:
                entity_id = None
            break
    return entity_type, entity_id


def derive_action(method: str, path: str) -> str:
    """Human-friendly action verb derived from method + trailing path token."""
    method = method.upper()
    last = path.rstrip("/").split("/")[-1]
    if last and not _UUID_RE.match(last) and not last.isdigit():
        action = last.replace("-", "_")[:40]
        # Compose a method-prefixed action for ambiguous endpoints.
        if method == "DELETE":
            return f"delete_{action}"
        if method == "POST":
            return f"create_{action}" if action.endswith("s") else action
        if method == "PATCH" or method == "PUT":
            return f"update_{action}"
    return {
        "POST": "create",
        "PUT": "update",
        "PATCH": "update",
        "DELETE": "delete",
    }.get(method, method.lower())


# ── Internal helpers ────────────────────────────────────────────────────────


def _should_audit(method: str, path: str) -> bool:
    if method not in _AUDIT_METHODS:
        return False
    if any(path.startswith(p) for p in _SKIP_PATH_PREFIXES):
        return False
    # Path may include "/api/v1" prefix — match against the un-prefixed tail too.
    tail = path
    for prefix in ("/api/v1", "/api"):
        if tail.startswith(prefix):
            tail = tail[len(prefix):] or "/"
            break
    if any(tail.startswith(p) for p in _SKIP_AUTH_PATHS):
        return False
    if any(tail.startswith(p) for p in _AUDIT_PATH_PREFIXES):
        return True
    if any(tail.startswith(p) for p in _AUDIT_EXACT_PATHS):
        return True
    return False


def _client_ip(request: Request) -> str | None:
    fwd = request.headers.get("x-forwarded-for")
    if fwd:
        return fwd.split(",")[0].strip()[:45]
    return request.client.host if request.client else None


def _extract_actor_id(request: Request) -> UUID | None:
    # Import lazily — auth.service imports models which import us only via __init__.
    from app.features.auth.service import decode_access_token

    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ", 1)[1]
    try:
        payload = decode_access_token(token)
    except Exception:
        return None
    sub = payload.get("sub")
    if not sub:
        return None
    try:
        return UUID(sub)
    except (ValueError, TypeError):
        return None


def _parse_body(raw: bytes | None) -> Any:
    if not raw:
        return None
    if len(raw) > _MAX_BODY_BYTES:
        return {"_truncated": True, "_size": len(raw)}
    try:
        return json.loads(raw)
    except Exception:
        # Probably form data or binary. Record a marker, not the bytes.
        return {"_non_json": True, "_size": len(raw)}


async def _persist(audit: AuditLog) -> None:
    try:
        async with async_session_factory() as session:
            session.add(audit)
            await session.commit()
    except Exception as exc:  # never let audit failure break the response
        logger.warning("Failed to persist audit row: %s", exc)


# ── Middleware ──────────────────────────────────────────────────────────────


class AuditMiddleware(BaseHTTPMiddleware):
    """
    Records every successful or attempted admin-panel mutation.

    Sits OUTSIDE the route handler — we capture the request body before
    handing it to downstream code, then schedule a non-blocking DB write
    after the response is generated.
    """

    async def dispatch(self, request: Request, call_next):
        method = request.method.upper()
        path = request.url.path

        if not _should_audit(method, path):
            return await call_next(request)

        # Buffer the body so the downstream handler can still read it.
        body_bytes = await request.body()

        async def _receive() -> dict:
            return {"type": "http.request", "body": body_bytes, "more_body": False}

        request._receive = _receive  # type: ignore[attr-defined]

        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = int((time.perf_counter() - start) * 1000)

        # Build the audit row outside the request critical path.
        try:
            actor_id = _extract_actor_id(request)
            entity_type, entity_id = derive_entity_from_path(path)
            action = derive_action(method, path)
            ua = request.headers.get("user-agent")
            req_id = getattr(request.state, "request_id", None)

            body_payload = scrub(_parse_body(body_bytes)) if body_bytes else None

            # Try to find the route summary for a friendly description.
            description: str | None = None
            route = getattr(request.scope.get("route"), "summary", None) if isinstance(
                request.scope.get("route"), object
            ) else None
            if route:
                description = str(route)[:255]
            elif path and method:
                description = f"{method} {path}"[:255]

            audit = AuditLog(
                actor_id=actor_id,
                entity_type=entity_type,
                entity_id=entity_id,
                action=action,
                description=description,
                method=method,
                path=path[:255],
                status_code=response.status_code,
                duration_ms=duration_ms,
                request_id=str(req_id)[:64] if req_id else None,
                user_agent=ua[:500] if ua else None,
                ip_address=_client_ip(request),
                old_value=None,
                new_value=body_payload if isinstance(body_payload, (dict, list)) else None,
            )

            asyncio.create_task(_persist(audit))
        except Exception as exc:
            logger.warning("AuditMiddleware capture failed: %s", exc)

        return response
