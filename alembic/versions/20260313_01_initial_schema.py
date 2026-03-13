"""initial schema"""

from alembic import op
import sqlalchemy as sa


revision = "20260313_01"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("username", sa.String(length=64), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("full_name", sa.String(length=255), nullable=True),
        sa.Column("role", sa.String(length=32), nullable=False, server_default="viewer"),
        sa.Column("password_hash", sa.String(length=512), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_users_username", "users", ["username"], unique=True)
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "invoices",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("warehub_id", sa.Integer(), nullable=True),
        sa.Column("source", sa.String(length=32), nullable=False, server_default="manual"),
        sa.Column("invoice_number", sa.String(length=128), nullable=False),
        sa.Column("company_name", sa.String(length=255), nullable=True),
        sa.Column("company_country", sa.String(length=16), nullable=True),
        sa.Column("company_country_name", sa.String(length=128), nullable=True),
        sa.Column("company_is_eu", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("amount", sa.Float(), nullable=False, server_default="0"),
        sa.Column("total_paid", sa.Float(), nullable=False, server_default="0"),
        sa.Column("remaining_amount", sa.Float(), nullable=False, server_default="0"),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="pending"),
        sa.Column("invoice_date", sa.Date(), nullable=True),
        sa.Column("production_date", sa.Date(), nullable=True),
        sa.Column("import_date", sa.Date(), nullable=True),
        sa.Column("due_date", sa.Date(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("seller_name", sa.String(length=255), nullable=True),
        sa.Column("seller_address", sa.Text(), nullable=True),
        sa.Column("seller_phone", sa.String(length=64), nullable=True),
        sa.Column("seller_email", sa.String(length=255), nullable=True),
        sa.Column("seller_website", sa.String(length=255), nullable=True),
        sa.Column("seller_contact_person", sa.String(length=255), nullable=True),
        sa.Column("seller_geolocation_label", sa.String(length=255), nullable=True),
        sa.Column("seller_latitude", sa.Float(), nullable=True),
        sa.Column("seller_longitude", sa.Float(), nullable=True),
        sa.Column("warehub_created_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("warehub_updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("assessment_payload", sa.JSON(), nullable=False),
        sa.Column("risk_payload", sa.JSON(), nullable=False),
        sa.Column("raw_payload", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_invoices_invoice_number", "invoices", ["invoice_number"], unique=False)
    op.create_index("ix_invoices_warehub_id", "invoices", ["warehub_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_invoices_warehub_id", table_name="invoices")
    op.drop_index("ix_invoices_invoice_number", table_name="invoices")
    op.drop_table("invoices")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_username", table_name="users")
    op.drop_table("users")
