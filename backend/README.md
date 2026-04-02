# Prime Business Network — Backend

Production-grade FastAPI backend for a B2B referral network platform.

## Tech Stack

| Layer        | Technology                         |
| ------------ | ---------------------------------- |
| Runtime      | Python 3.12                        |
| Framework    | FastAPI (async)                    |
| ORM          | SQLAlchemy 2.x (async sessions)    |
| Migrations   | Alembic (async PostgreSQL)         |
| Database     | PostgreSQL 16                      |
| Cache / OTP  | Redis 7                            |
| ASGI Server  | Uvicorn                            |
| Config       | pydantic-settings                  |
| Containers   | Docker Compose                     |

## Project Structure

```
backend/
├── alembic/                  # Migration scripts
│   ├── env.py                # Async migration environment
│   ├── script.py.mako        # Migration template
│   └── versions/             # Auto-generated revisions
├── app/
│   ├── core/
│   │   ├── config.py         # pydantic-settings (.env)
│   │   ├── database.py       # Async SQLAlchemy engine
│   │   ├── redis.py          # Redis connection pool
│   │   ├── dependencies.py   # DI: get_db, get_redis
│   │   ├── exceptions.py     # Custom exception hierarchy
│   │   └── response.py       # Standard API response wrapper
│   ├── features/             # Feature modules (per phase)
│   ├── models/
│   │   ├── __init__.py
│   │   └── base.py           # Declarative Base + TimestampMixin
│   └── main.py               # App factory, middleware, routes
├── .env.example              # Environment template
├── alembic.ini               # Alembic configuration
├── docker-compose.yml        # FastAPI + Postgres + Redis
├── Dockerfile                # Python 3.12 slim image
├── requirements.txt          # Pinned dependencies
└── README.md                 # ← You are here
```

## Quick Start

### 1. Clone & configure environment

```bash
cd backend
cp .env.example .env
# Edit .env with your own SECRET_KEY and credentials
```

### 2. Run with Docker Compose (recommended)

```bash
docker compose up --build
```

This starts:
- **FastAPI** on `http://localhost:8000`
- **PostgreSQL 16** on `localhost:5432`
- **Redis 7** on `localhost:6379`

### 3. Run without Docker

```bash
# Create virtual environment
python -m venv .venv
.venv\Scripts\activate    # Windows
# source .venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Start PostgreSQL and Redis separately, then:
uvicorn app.main:app --reload --port 8000
```

### 4. Verify

```bash
# Health check (database + Redis connectivity)
curl http://localhost:8000/health

# Root endpoint
curl http://localhost:8000/
```

## Database Migrations

```bash
# Create a new migration after model changes
alembic revision --autogenerate -m "describe your change"

# Apply all pending migrations
alembic upgrade head

# Rollback one step
alembic downgrade -1
```

## API Response Format

Every endpoint returns a consistent envelope:

```json
{
  "status": "success",
  "data": { "...payload..." },
  "message": null,
  "code": null
}
```

On error:

```json
{
  "status": "error",
  "data": null,
  "message": "Resource not found.",
  "code": "NOT_FOUND"
}
```

## API Documentation

When `DEBUG=true`, interactive docs are available at:

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## Adding a New Feature

1. Create a new directory under `app/features/`:
   ```
   app/features/auth/
   ├── __init__.py
   ├── router.py      # FastAPI router
   ├── schemas.py      # Pydantic request/response models
   ├── service.py      # Business logic
   ├── models.py       # SQLAlchemy models
   └── dependencies.py # Feature-specific DI
   ```
2. Register the router in `app/main.py` under `_register_routes()`.
3. Create a migration: `alembic revision --autogenerate -m "add auth tables"`
4. Apply it: `alembic upgrade head`

## License

Proprietary — Prime Business Network © 2026
