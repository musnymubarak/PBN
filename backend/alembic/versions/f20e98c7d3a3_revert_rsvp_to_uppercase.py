"""revert rsvp status to uppercase

Revision ID: f20e98c7d3a3
Revises: f20e98c7d3a2
Create Date: 2026-04-21 12:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f20e98c7d3a3'
down_revision: Union[str, None] = 'f20e98c7d3a2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # SQLAlchemy uses enum NAMES (uppercase) not VALUES (lowercase)
    # The previous migration broke this by renaming to lowercase.
    # We must revert to uppercase to match SQLAlchemy's expectations.
    with op.get_context().autocommit_block():
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'going' TO 'GOING'")
        except Exception:
            pass
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'not_going' TO 'NOT_GOING'")
        except Exception:
            pass
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'maybe' TO 'MAYBE'")
        except Exception:
            pass
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'requested' TO 'REQUESTED'")
        except Exception:
            pass

        # Ensure REQUESTED exists as uppercase if it was never added
        try:
            op.execute("ALTER TYPE rsvp_status ADD VALUE 'REQUESTED'")
        except Exception:
            pass


def downgrade() -> None:
    pass
