"""fix rsvp status enum

Revision ID: f20e98c7d3a1
Revises: d572a5bc077c, 4ac1fa336316
Create Date: 2026-04-21 11:34:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f20e98c7d3a1'
down_revision: Union[str, None] = 'd572a5bc077c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Force rename of uppercase values to lowercase to match Python models
    # This must be done outside of a transaction for some Postgres versions
    with op.get_context().autocommit_block():
        # 1. Rename existing uppercase values to lowercase
        # These are the values defined in the initial migration b9de2f4fa83a
        op.execute("ALTER TYPE rsvp_status RENAME VALUE 'GOING' TO 'going'")
        op.execute("ALTER TYPE rsvp_status RENAME VALUE 'NOT_GOING' TO 'not_going'")
        op.execute("ALTER TYPE rsvp_status RENAME VALUE 'MAYBE' TO 'maybe'")
        
        # 2. Add 'requested' value (lowercase)
        # Note: If it already exists as Ginas/UpperCase 'REQUESTED' from a failed attempt, 
        # we might need to handle it. The logs show 'REQUESTED' is present.
        try:
            op.execute("ALTER TYPE rsvp_status ADD VALUE 'requested'")
        except Exception:
            # If 'requested' already exists lowercase, ignore. 
            # If it exists as 'REQUESTED', we rename it below.
            pass

        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'REQUESTED' TO 'requested'")
        except Exception:
            pass


def downgrade() -> None:
    with op.get_context().autocommit_block():
        op.execute("ALTER TYPE rsvp_status RENAME VALUE 'going' TO 'GOING'")
        op.execute("ALTER TYPE rsvp_status RENAME VALUE 'not_going' TO 'NOT_GOING'")
        op.execute("ALTER TYPE rsvp_status RENAME VALUE 'maybe' TO 'MAYBE'")
        op.execute("ALTER TYPE rsvp_status RENAME VALUE 'requested' TO 'REQUESTED'") 
