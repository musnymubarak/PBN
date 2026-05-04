"""
Prime Business Network – Application Settings.

All configuration is loaded from environment variables (or a .env file)
via pydantic-settings.  Every setting has a sensible default for local
development so the app can start with a bare `.env` copy.
"""

from __future__ import annotations

from functools import lru_cache
from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central configuration loaded once and cached."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Application ──────────────────────────────────────────
    APP_NAME: str = "Prime Business Network"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"  # development | staging | production
    API_V1_PREFIX: str = "/api/v1"

    # ── Security ─────────────────────────────────────────────
    SECRET_KEY: str = "change-me"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # ── PostgreSQL ───────────────────────────────────────────
    POSTGRES_USER: str = "pbn_user"
    POSTGRES_PASSWORD: str = "pbn_secret_password"
    POSTGRES_DB: str = "pbn_db"
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    DATABASE_URL: str = (
        "postgresql+asyncpg://pbn_user:pbn_secret_password@localhost:5432/pbn_db"
    )

    # ── Redis ────────────────────────────────────────────────
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: str = ""
    REDIS_DB: int = 0
    REDIS_URL: str = "redis://localhost:6379/0"

    # ── WebxPay ───────────────────────────────────────────────
    WEBXPAY_MERCHANT_ID: str = ""
    WEBXPAY_SECRET_KEY: str = ""
    WEBXPAY_API_URL: str = "https://pay.webxpay.com/index.php"
    WEBXPAY_RETURN_URL: str = "http://localhost:8000/api/v1/payments/return"
    WEBXPAY_CANCEL_URL: str = "http://localhost:8000/api/v1/payments/cancel"
    WEBXPAY_NOTIFY_URL: str = "http://localhost:8000/api/v1/payments/webhook"

    FIREBASE_SERVICE_ACCOUNT_JSON: str | None = None
    GEMINI_API_KEY: str | None = None

    # ── SMTP / Email ──────────────────────────────────────────
    SMTP_HOST: str = "mail.primebusiness.network"
    SMTP_PORT: int = 465
    SMTP_USER: str = "info@primebusiness.network"
    SMTP_PASSWORD: str = ""
    SMTP_FROM_NAME: str = "Prime Business Network"
    SMTP_FROM_EMAIL: str = "info@primebusiness.network"

    # ── CORS ─────────────────────────────────────────────────
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:5173"]

    # ── Validators ───────────────────────────────────────────
    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def _parse_cors(cls, v: str | list) -> list:
        if isinstance(v, str):
            import json

            try:
                return json.loads(v)
            except json.JSONDecodeError:
                return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v


@lru_cache
def get_settings() -> Settings:
    """Return a cached singleton of the application settings."""
    return Settings()
