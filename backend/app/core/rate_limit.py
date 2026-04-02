"""
Prime Business Network – Rate Limiting Middleware.

Uses Redis sliding-window counters to enforce per-IP rate limits.
Gracefully degrades (allows requests) if Redis is unavailable.
"""

from __future__ import annotations

import logging
import time
from typing import Callable

from fastapi import Request, Response
from fastapi.responses import ORJSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.config import get_settings

logger = logging.getLogger(__name__)

# Rate limit configuration
RATE_LIMITS = {
    "default": {"requests": 60, "window": 60},        # 60 req/min
    "auth": {"requests": 10, "window": 60},            # 10 req/min for auth
    "webhook": {"requests": 100, "window": 60},        # 100 req/min for webhooks
}


def _get_limit_tier(path: str) -> dict:
    """Determine rate limit tier based on request path."""
    if "/auth/" in path:
        return RATE_LIMITS["auth"]
    if "/webhook" in path:
        return RATE_LIMITS["webhook"]
    return RATE_LIMITS["default"]


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        settings = get_settings()
        if settings.ENVIRONMENT == "development":
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        path = request.url.path
        tier = _get_limit_tier(path)

        try:
            from app.core.redis import get_redis_client
            redis = get_redis_client()

            key = f"ratelimit:{client_ip}:{path.split('/')[3] if len(path.split('/')) > 3 else 'root'}"
            now = int(time.time())
            window_start = now - tier["window"]

            pipe = redis.pipeline()
            await pipe.zremrangebyscore(key, 0, window_start)
            await pipe.zadd(key, {str(now) + f":{id(request)}": now})
            await pipe.zcard(key)
            await pipe.expire(key, tier["window"])
            results = await pipe.execute()

            current_count = results[2]

            if current_count > tier["requests"]:
                logger.warning(f"Rate limit exceeded for {client_ip} on {path}")
                return ORJSONResponse(
                    status_code=429,
                    content={
                        "status": "error",
                        "data": None,
                        "message": "Too many requests. Please try again later.",
                        "code": "RATE_LIMIT_EXCEEDED",
                    },
                    headers={
                        "Retry-After": str(tier["window"]),
                        "X-RateLimit-Limit": str(tier["requests"]),
                        "X-RateLimit-Remaining": "0",
                    },
                )

            response = await call_next(request)
            response.headers["X-RateLimit-Limit"] = str(tier["requests"])
            response.headers["X-RateLimit-Remaining"] = str(max(0, tier["requests"] - current_count))
            return response

        except Exception:
            # If Redis fails, allow request through
            return await call_next(request)
