from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from dependencies.security import require_roles
from models.audit import AuditLogListResponse
from models.db import UserRecord
from models.user import UserRole
from services.audit import list_audit_logs
from services.database import get_db


router = APIRouter(prefix="/api/v1/audit-logs", tags=["Audit"])


@router.get("", response_model=AuditLogListResponse)
def get_audit_logs(
    entity_type: str | None = None,
    entity_id: str | None = None,
    limit: int = 100,
    _: UserRecord = Depends(require_roles(UserRole.admin, UserRole.analyst, UserRole.reviewer)),
    db: Session = Depends(get_db),
):
    return list_audit_logs(db, entity_type=entity_type, entity_id=entity_id, limit=limit)
