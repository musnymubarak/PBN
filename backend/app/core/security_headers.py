"""
Prime Business Network – Security Headers Middleware.

Injects defensive HTTP headers into every response to mitigate
XSS, clickjacking, MIME-sniffing, and other common web attacks.
"""

from __future__ import annotations

from typing import Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)

        # Don't add security headers to CORS preflight responses
        if request.method == "OPTIONS":
            return response

        # Prevent MIME type sniffing
        response.headers["X-Content-Type-Options"] = "nosniff"

        # Prevent clickjacking
        if request.url.path.startswith("/static"):
            response.headers["X-Frame-Options"] = "SAMEORIGIN"
        else:
            response.headers["X-Frame-Options"] = "DENY"

        # XSS filter
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # Strict Transport Security (only meaningful over HTTPS)
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

        # Referrer Policy
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # Content Security Policy (Strict for API, loose for HTML pages)
        if request.url.path.startswith("/verify"):
            # Allow inline styles/scripts and base64 images for the verification HTML template
            response.headers["Content-Security-Policy"] = (
                "default-src 'self'; "
                "style-src 'self' 'unsafe-inline'; "
                "script-src 'self' 'unsafe-inline'; "
                "img-src 'self' data:; "
                "connect-src 'self'; "
                "frame-ancestors 'none'"
            )
        elif request.url.path.startswith("/static"):
            # Allow static files to be framed/embedded by the application itself
            response.headers["Content-Security-Policy"] = (
                "default-src 'self'; "
                "frame-ancestors 'self' https://admin.primebusiness.network https://primebusiness.network http://localhost:3000 http://localhost:8000"
            )
        else:
            response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"

        # Permissions Policy
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"

        return response
