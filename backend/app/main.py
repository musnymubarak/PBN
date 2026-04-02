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
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
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

    app.include_router(auth_router, prefix=settings.API_V1_PREFIX)

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
