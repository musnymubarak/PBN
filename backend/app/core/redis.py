"""
Prime Business Network – Redis Connection Pool.

Provides an async Redis client backed by a connection pool.
Used for caching, OTP storage, and rate limiting.

In development, falls back to fakeredis if a real Redis server
is unavailable — so the app boots without Redis running.
"""

from __future__ import annotations

import logging

import redis.asyncio as aioredis

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

redis_client: aioredis.Redis | None = None


async def init_redis() -> aioredis.Redis:
    """Initialise and return the Redis client, falling back to fakeredis."""
    global redis_client

    try:
        pool = aioredis.ConnectionPool.from_url(
            settings.REDIS_URL,
            decode_responses=True,
            max_connections=20,
        )
        client = aioredis.Redis(connection_pool=pool)
        await client.ping()
        redis_client = client
        logger.info("Connected to Redis at %s", settings.REDIS_URL)
    except Exception:
        logger.warning(
            "Real Redis unavailable – falling back to fakeredis (dev only)."
        )
        try:
            import fakeredis.aioredis as fake

            redis_client = fake.FakeRedis(decode_responses=True)
        except ImportError:
            raise RuntimeError(
                "Redis is not available and fakeredis is not installed. "
                "Install fakeredis (`pip install fakeredis`) for local dev "
                "or start a Redis server."
            )

    return redis_client


def get_redis_client() -> aioredis.Redis:
    """Return the initialised Redis client (call init_redis first)."""
    if redis_client is None:
        raise RuntimeError("Redis not initialised. Call init_redis() first.")
    return redis_client
