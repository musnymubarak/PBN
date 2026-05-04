"""
Prime Business Network – FastAPI Application Factory.

Creates the app, registers middleware, exception handlers, and routes.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import ORJSONResponse
from sqlalchemy import text

from app.core.config import get_settings
from app.core.database import engine
from app.core.exceptions import AppException
from app.core.redis import get_redis_client, init_redis
from app.core.response import error_response, success_response

logger = logging.getLogger(__name__)
settings = get_settings()


# ── Lifespan ─────────────────────────────────────────────────────────────────


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncGenerator[None, None]:
    """Startup / shutdown events."""
    # Startup
    logging.basicConfig(
        level=logging.DEBUG if settings.DEBUG else logging.INFO,
        format="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
    )
    logger.info("Starting %s v%s [%s]", settings.APP_NAME, settings.APP_VERSION, settings.ENVIRONMENT)
    await init_redis()
    logger.info("Infrastructure ready.")

    yield

    # Shutdown
    await engine.dispose()
    redis = get_redis_client()
    await redis.aclose()
    logger.info("Shutdown complete.")


# ── App Factory ──────────────────────────────────────────────────────────────


def create_app() -> FastAPI:
    """Build and return the FastAPI application."""
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
        openapi_url="/openapi.json" if settings.DEBUG else None,
        default_response_class=ORJSONResponse,
        lifespan=lifespan,
    )

    _register_middleware(app)
    _register_exception_handlers(app)
    _register_routes(app)

    return app


# ── Middleware ───────────────────────────────────────────────────────────────


def _register_middleware(app: FastAPI) -> None:
    # Request correlation ID (must come first)
    from app.core.request_id import RequestIDMiddleware
    app.add_middleware(RequestIDMiddleware)

    # Security headers on every response
    from app.core.security_headers import SecurityHeadersMiddleware
    app.add_middleware(SecurityHeadersMiddleware)

    # Rate limiting (disabled in development via env check inside)
    from app.core.rate_limit import RateLimitMiddleware
    app.add_middleware(RateLimitMiddleware)

    # CORS (Must be outermost to handle preflights correctly)
    # In development, allow all origins since Flutter web uses random ports
    origins = ["*"] if settings.ENVIRONMENT == "development" else settings.CORS_ORIGINS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=False if settings.ENVIRONMENT == "development" else True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# ── Exception Handlers ──────────────────────────────────────────────────────


def _register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def _app_exception_handler(
        _request: Request, exc: AppException
    ) -> ORJSONResponse:
        return error_response(
            message=exc.message,
            code=exc.code,
            status_code=exc.status_code,
            data=exc.data,
        )

    @app.exception_handler(Exception)
    async def _unhandled_exception_handler(
        _request: Request, exc: Exception
    ) -> ORJSONResponse:
        logger.exception("Unhandled exception: %s", exc)
        return error_response(
            message="An unexpected error occurred.",
            code="INTERNAL_ERROR",
            status_code=500,
        )


# ── Routes ───────────────────────────────────────────────────────────────────


def _register_routes(app: FastAPI) -> None:
    # ── Feature Routers ──────────────────────────────────────────────────
    from app.features.auth.router import router as auth_router
    from app.features.applications.router import router as app_router
    from app.features.chapters.router import router as chap_router
    from app.features.referrals.router import router as ref_router
    from app.features.events.router import router as ev_router
    from app.features.rewards.router import router as rew_router
    from app.features.analytics.router import router as an_router
    from app.features.payments.router import router as pay_router
    from app.features.notifications.router import router as notif_router
    from app.features.admin.router import router as admin_router
    from app.features.community.router import router as comm_router
    from app.features.horizontal_clubs.router import router as club_router
    from app.features.marketplace.router import router as market_router
    from fastapi.staticfiles import StaticFiles
    import os

    os.makedirs("uploads/profiles", exist_ok=True)
    os.makedirs("uploads/partners", exist_ok=True)
    os.makedirs("uploads/events", exist_ok=True)
    app.mount("/static", StaticFiles(directory="uploads"), name="static")

    app.include_router(auth_router, prefix=settings.API_V1_PREFIX)
    app.include_router(app_router, prefix=settings.API_V1_PREFIX)
    app.include_router(chap_router, prefix=settings.API_V1_PREFIX + "/chapters")
    app.include_router(ref_router, prefix=settings.API_V1_PREFIX)
    app.include_router(ev_router, prefix=settings.API_V1_PREFIX)
    app.include_router(rew_router, prefix=settings.API_V1_PREFIX)
    app.include_router(an_router, prefix=settings.API_V1_PREFIX)
    app.include_router(pay_router, prefix=settings.API_V1_PREFIX)
    app.include_router(notif_router, prefix=settings.API_V1_PREFIX)
    app.include_router(admin_router, prefix=settings.API_V1_PREFIX)
    app.include_router(comm_router, prefix=settings.API_V1_PREFIX)
    app.include_router(club_router, prefix=settings.API_V1_PREFIX)
    app.include_router(market_router, prefix=settings.API_V1_PREFIX + "/marketplace")

    # ── Infrastructure Endpoints ─────────────────────────────────────────
    @app.get("/health", tags=["Infrastructure"])
    async def health_check() -> ORJSONResponse:
        """Return database and Redis connectivity status."""
        health: dict = {"database": "connected", "redis": "connected"}
        overall = "healthy"

        # Check PostgreSQL
        try:
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
        except Exception as exc:
            health["database"] = f"disconnected: {exc}"
            overall = "degraded"

        # Check Redis
        try:
            redis = get_redis_client()
            await redis.ping()
        except Exception as exc:
            health["redis"] = f"disconnected: {exc}"
            overall = "degraded"

        status_code = 200 if overall == "healthy" else 503
        return success_response(
            data={
                "status": overall,
                "version": settings.APP_VERSION,
                "services": health,
            },
            status_code=status_code,
        )

    @app.get("/", tags=["Infrastructure"])
    async def root() -> ORJSONResponse:
        return success_response(
            data={
                "name": settings.APP_NAME,
                "version": settings.APP_VERSION,
                "docs": "/docs" if settings.DEBUG else None,
            },
        )


# ── Application Instance ────────────────────────────────────────────────────

app = create_app()
