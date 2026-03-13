from __future__ import annotations

from datetime import date, datetime
from typing import Any

from sqlalchemy import JSON, Boolean, Date, DateTime, Float, Integer, String, Text, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class UserRecord(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    username: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    role: Mapped[str] = mapped_column(String(32), default="viewer", nullable=False)
    password_hash: Mapped[str] = mapped_column(String(512), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class RefreshTokenRecord(Base):
    __tablename__ = "refresh_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    token_id: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, nullable=False, index=True)
    user_agent: Mapped[str | None] = mapped_column(String(512), nullable=True)
    issued_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    replaced_by_token_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class AuditLogRecord(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    actor_user_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    actor_username: Mapped[str | None] = mapped_column(String(64), nullable=True)
    actor_role: Mapped[str | None] = mapped_column(String(32), nullable=True)
    action: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    entity_type: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    entity_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    summary: Mapped[str | None] = mapped_column(String(512), nullable=True)
    payload: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )


class InvoiceRecord(Base):
    __tablename__ = "invoices"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    warehub_id: Mapped[int | None] = mapped_column(Integer, unique=True, nullable=True, index=True)
    source: Mapped[str] = mapped_column(String(32), default="manual", nullable=False)
    invoice_number: Mapped[str] = mapped_column(String(128), index=True)
    company_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    company_country: Mapped[str | None] = mapped_column(String(16), nullable=True)
    company_country_name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    company_is_eu: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    amount: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    total_paid: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    remaining_amount: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="pending", nullable=False)
    invoice_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    production_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    import_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    due_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, default="", nullable=True)
    seller_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    seller_address: Mapped[str | None] = mapped_column(Text, nullable=True)
    seller_phone: Mapped[str | None] = mapped_column(String(64), nullable=True)
    seller_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    seller_website: Mapped[str | None] = mapped_column(String(255), nullable=True)
    seller_contact_person: Mapped[str | None] = mapped_column(String(255), nullable=True)
    seller_geolocation_label: Mapped[str | None] = mapped_column(String(255), nullable=True)
    seller_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    seller_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    warehub_created_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    warehub_updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    synced_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    assessment_payload: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict, nullable=False)
    risk_payload: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict, nullable=False)
    raw_payload: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
