"""extend audit_logs for admin panel

Adds method, path, status_code, duration_ms, request_id, user_agent, description
columns and an (actor_id, created_at) composite index. Also relaxes entity_id to
nullable so middleware-captured rows that don't target a specific entity can be
recorded.

Revision ID: d8e7f6a4b2c1
Revises: c2d4e6f8a1b3
Create Date: 2026-05-21 04:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


revision: str = "d8e7f6a4b2c1"
down_revision: Union[str, None] = "c2d4e6f8a1b3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("audit_logs", sa.Column("description", sa.String(length=255), nullable=True))
    op.add_column("audit_logs", sa.Column("method", sa.String(length=10), nullable=True))
    op.add_column("audit_logs", sa.Column("path", sa.String(length=255), nullable=True))
    op.add_column("audit_logs", sa.Column("status_code", sa.Integer(), nullable=True))
    op.add_column("audit_logs", sa.Column("duration_ms", sa.Integer(), nullable=True))
    op.add_column("audit_logs", sa.Column("request_id", sa.String(length=64), nullable=True))
    op.add_column("audit_logs", sa.Column("user_agent", sa.String(length=500), nullable=True))

    op.alter_column("audit_logs", "entity_id", existing_type=sa.dialects.postgresql.UUID(), nullable=True)

    op.create_index(
        "ix_audit_logs_actor_created",
        "audit_logs",
        ["actor_id", "created_at"],
    )
    op.create_index("ix_audit_logs_action", "audit_logs", ["action"])


def downgrade() -> None:
    op.drop_index("ix_audit_logs_action", table_name="audit_logs")
    op.drop_index("ix_audit_logs_actor_created", table_name="audit_logs")
    op.alter_column("audit_logs", "entity_id", existing_type=sa.dialects.postgresql.UUID(), nullable=False)
    op.drop_column("audit_logs", "user_agent")
    op.drop_column("audit_logs", "request_id")
    op.drop_column("audit_logs", "duration_ms")
    op.drop_column("audit_logs", "status_code")
    op.drop_column("audit_logs", "path")
    op.drop_column("audit_logs", "method")
    op.drop_column("audit_logs", "description")
