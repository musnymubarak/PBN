#!/bin/sh

# Stop on error
set -e

echo "Running database migrations..."
alembic upgrade head

echo "Starting application..."
exec "$@"
