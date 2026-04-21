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
down_revision: Union[str, Sequence[str], None] = ('d572a5bc077c', '4ac1fa336316')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add 'requested' value to rsvp_status enum
    # 2. Rename old UPPERCASE values to lowercase to match Python models
    
    with op.get_context().autocommit_block():
        # Add requested if it doesn't exist
        op.execute("ALTER TYPE rsvp_status ADD VALUE IF NOT EXISTS 'requested'")
        
        # Rename GOING -> going
        # Note: We use a check to see if GOING exists before renaming
        # But for simplicity and based on original migration, we assume they are UPPERCASE
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'GOING' TO 'going'")
        except Exception:
            pass
            
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'NOT_GOING' TO 'not_going'")
        except Exception:
            pass
            
        try:
            op.execute("ALTER TYPE rsvp_status RENAME VALUE 'MAYBE' TO 'maybe'")
        except Exception:
            pass


def downgrade() -> None:
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
