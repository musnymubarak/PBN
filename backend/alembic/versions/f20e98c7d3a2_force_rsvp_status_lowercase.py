"""force rsvp status lowercase

Revision ID: f20e98c7d3a2
Revises: f20e98c7d3a1
Create Date: 2026-04-21 11:45:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f20e98c7d3a2'
down_revision: Union[str, None] = 'f20e98c7d3a1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # This migration forces the rsvp_status enum values to be lowercase
    with op.get_context().autocommit_block():
        # 1. Rename existing uppercase values to lowercase
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'GOING' TO 'going'")
        except Exception: pass
            
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'NOT_GOING' TO 'not_going'")
        except Exception: pass
            
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'MAYBE' TO 'maybe'")
        except Exception: pass
        
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'REQUESTED' TO 'requested'")
        except Exception: pass
        
        # 2. Ensure 'requested' exists (lowercase) if it wasn't added yet
        try:
            op.execute("ALTER TYPE rsvp_status ADD VALUE 'requested'")
        except Exception: pass


def downgrade() -> None:
    with op.get_context().autocommit_block():
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'going' TO 'GOING'")
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'not_going' TO 'NOT_GOING'")
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'maybe' TO 'MAYBE'")
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'requested' TO 'REQUESTED'")
        except Exception: pass
