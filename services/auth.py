from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import jwt
from fastapi import HTTPException, status
from pwdlib import PasswordHash
from sqlalchemy import func, inspect, or_
from sqlalchemy.orm import Session

from config.settings import get_settings
from models.db import RefreshTokenRecord, UserRecord
from models.user import (
    LogoutRequest,
    RefreshTokenRequest,
    TokenResponse,
    UserCreate,
    UserPublic,
    UserRole,
)
from services.audit import log_audit_event


password_hash = PasswordHash.recommended()
settings = get_settings()


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


def _ensure_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def _hash_refresh_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def _refresh_expiry_delta() -> timedelta:
    return timedelta(days=settings.refresh_token_expire_days)


def hash_password(password: str) -> str:
    return password_hash.hash(password)


def verify_password(password: str, password_digest: str) -> bool:
    return password_hash.verify(password, password_digest)


def serialize_user(user: UserRecord) -> UserPublic:
    return UserPublic.model_validate(user)


def create_access_token(user: UserRecord) -> tuple[str, int]:
    expires_delta = timedelta(minutes=settings.access_token_expire_minutes)
    expires_at = _now_utc() + expires_delta
    payload = {
        "sub": str(user.id),
        "username": user.username,
        "role": user.role,
        "exp": expires_at,
    }
    token = jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)
    return token, int(expires_delta.total_seconds())


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    except jwt.PyJWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired access token.",
        ) from exc


def get_user_by_username_or_email(db: Session, identifier: str) -> UserRecord | None:
    normalized = identifier.strip().lower()
    return (
        db.query(UserRecord)
        .filter(
            or_(
                func.lower(UserRecord.username) == normalized,
                func.lower(UserRecord.email) == normalized,
            )
        )
        .one_or_none()
    )


def authenticate_user(db: Session, username: str, password: str) -> UserRecord:
    user = get_user_by_username_or_email(db, username)
    if user is None or not verify_password(password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password.",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive.",
        )
    return user


def _issue_refresh_token(
    db: Session,
    *,
    user: UserRecord,
    user_agent: str | None = None,
    replaced_by: RefreshTokenRecord | None = None,
) -> tuple[str, RefreshTokenRecord]:
    raw_token = secrets.token_urlsafe(64)
    token_record = RefreshTokenRecord(
        user_id=user.id,
        token_id=uuid4().hex,
        token_hash=_hash_refresh_token(raw_token),
        user_agent=user_agent[:512] if user_agent else None,
        issued_at=_now_utc(),
        expires_at=_now_utc() + _refresh_expiry_delta(),
    )
    db.add(token_record)
    db.flush()

    if replaced_by is not None:
        replaced_by.revoked_at = _now_utc()
        replaced_by.replaced_by_token_id = token_record.token_id

    return raw_token, token_record


def _build_token_response(
    db: Session,
    *,
    user: UserRecord,
    user_agent: str | None = None,
    replaced_by: RefreshTokenRecord | None = None,
) -> TokenResponse:
    access_token, expires_in = create_access_token(user)
    refresh_token, refresh_record = _issue_refresh_token(
        db,
        user=user,
        user_agent=user_agent,
        replaced_by=replaced_by,
    )
    refresh_expires_in = int((_ensure_utc(refresh_record.expires_at) - _now_utc()).total_seconds())
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=expires_in,
        refresh_expires_in=refresh_expires_in,
        user=serialize_user(user),
    )


def login_user(db: Session, username: str, password: str, user_agent: str | None = None) -> TokenResponse:
    user = authenticate_user(db, username, password)
    response = _build_token_response(db, user=user, user_agent=user_agent)
    db.commit()
    log_audit_event(
        db,
        action="auth.login",
        entity_type="user",
        entity_id=user.id,
        summary=f"User {user.username} signed in.",
        payload={"user_agent": user_agent},
        actor=user,
    )
    return response


def _resolve_refresh_token_record(db: Session, refresh_token: str) -> RefreshTokenRecord:
    token_hash = _hash_refresh_token(refresh_token)
    token_record = (
        db.query(RefreshTokenRecord)
        .filter(RefreshTokenRecord.token_hash == token_hash)
        .one_or_none()
    )
    if token_record is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token is invalid.")
    if token_record.revoked_at is not None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token has been revoked.")
    if _ensure_utc(token_record.expires_at) <= _now_utc():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token has expired.")
    return token_record


def refresh_user_session(
    db: Session,
    payload: RefreshTokenRequest,
    *,
    user_agent: str | None = None,
) -> TokenResponse:
    token_record = _resolve_refresh_token_record(db, payload.refresh_token)
    user = db.get(UserRecord, token_record.user_id)
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not available for refresh.")

    response = _build_token_response(db, user=user, user_agent=user_agent, replaced_by=token_record)
    db.commit()
    log_audit_event(
        db,
        action="auth.refresh",
        entity_type="user",
        entity_id=user.id,
        summary=f"Refresh token rotated for {user.username}.",
        payload={"user_agent": user_agent, "replaced_token_id": token_record.token_id},
        actor=user,
    )
    return response


def revoke_refresh_token(
    db: Session,
    payload: LogoutRequest,
    *,
    summary: str = "Session signed out.",
) -> None:
    token_hash = _hash_refresh_token(payload.refresh_token)
    token_record = (
        db.query(RefreshTokenRecord)
        .filter(RefreshTokenRecord.token_hash == token_hash)
        .one_or_none()
    )
    if token_record is None:
        return

    if token_record.revoked_at is None:
        token_record.revoked_at = _now_utc()
        db.add(token_record)
        db.commit()

    user = db.get(UserRecord, token_record.user_id)
    log_audit_event(
        db,
        action="auth.logout",
        entity_type="user",
        entity_id=user.id if user else None,
        summary=summary,
        payload={"token_id": token_record.token_id},
        actor=user,
    )


def create_user(db: Session, payload: UserCreate, actor: UserRecord | None = None) -> UserRecord:
    existing = get_user_by_username_or_email(db, payload.username) or get_user_by_username_or_email(db, payload.email)
    if existing is not None:
        raise HTTPException(status_code=409, detail="User with that username or email already exists.")

    user = UserRecord(
        username=payload.username.strip(),
        email=str(payload.email).lower(),
        full_name=payload.full_name,
        role=payload.role.value,
        password_hash=hash_password(payload.password),
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    log_audit_event(
        db,
        action="user.create",
        entity_type="user",
        entity_id=user.id,
        summary=f"User {user.username} created.",
        payload={"role": user.role},
        actor=actor,
    )
    return user


def update_user_record(
    db: Session,
    user: UserRecord,
    *,
    full_name: str | None = None,
    role: UserRole | None = None,
    is_active: bool | None = None,
    password: str | None = None,
    actor: UserRecord | None = None,
) -> UserRecord:
    changes: dict[str, str | bool | None] = {}
    if full_name is not None:
        user.full_name = full_name
        changes["full_name"] = full_name
    if role is not None:
        user.role = role.value
        changes["role"] = role.value
    if is_active is not None:
        user.is_active = is_active
        changes["is_active"] = is_active
    if password:
        user.password_hash = hash_password(password)
        changes["password"] = "***"

    db.add(user)
    db.commit()
    db.refresh(user)
    log_audit_event(
        db,
        action="user.update",
        entity_type="user",
        entity_id=user.id,
        summary=f"User {user.username} updated.",
        payload=changes,
        actor=actor,
    )
    return user


def ensure_bootstrap_admin(db: Session) -> UserRecord | None:
    if not settings.auto_seed_admin:
        return None
    if db.bind is None:
        return None
    if "users" not in inspect(db.bind).get_table_names():
        return None

    existing_count = db.query(UserRecord).count()
    if existing_count > 0:
        return db.query(UserRecord).filter(func.lower(UserRecord.username) == settings.bootstrap_admin_username.lower()).one_or_none()

    admin = UserRecord(
        username=settings.bootstrap_admin_username,
        email=settings.bootstrap_admin_email.lower(),
        full_name=settings.bootstrap_admin_full_name,
        role=UserRole.admin.value,
        password_hash=hash_password(settings.bootstrap_admin_password),
        is_active=True,
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    log_audit_event(
        db,
        action="user.bootstrap_admin",
        entity_type="user",
        entity_id=admin.id,
        summary=f"Bootstrap admin {admin.username} created.",
        payload={"role": admin.role},
        actor=admin,
    )
    return admin
