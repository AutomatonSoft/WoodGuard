from __future__ import annotations

from sqlalchemy.orm import Session

from models.audit import AuditLogEntry, AuditLogListResponse
from models.db import AuditLogRecord, UserRecord


def log_audit_event(
    db: Session,
    *,
    action: str,
    entity_type: str,
    entity_id: str | int | None = None,
    summary: str | None = None,
    payload: dict | None = None,
    actor: UserRecord | None = None,
    commit: bool = True,
) -> AuditLogRecord:
    entry = AuditLogRecord(
        actor_user_id=actor.id if actor else None,
        actor_username=actor.username if actor else None,
        actor_role=actor.role if actor else None,
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        summary=summary,
        payload=payload or {},
    )
    db.add(entry)
    if commit:
        db.commit()
        db.refresh(entry)
    return entry


def serialize_audit_log(record: AuditLogRecord) -> AuditLogEntry:
    return AuditLogEntry.model_validate(record)


def list_audit_logs(
    db: Session,
    *,
    entity_type: str | None = None,
    entity_id: str | int | None = None,
    limit: int = 100,
) -> AuditLogListResponse:
    query = db.query(AuditLogRecord)
    if entity_type:
        query = query.filter(AuditLogRecord.entity_type == entity_type)
    if entity_id is not None:
        query = query.filter(AuditLogRecord.entity_id == str(entity_id))

    records = query.order_by(AuditLogRecord.id.desc()).limit(limit).all()
    items = [serialize_audit_log(record) for record in records]
    return AuditLogListResponse(items=items, total=len(items))
