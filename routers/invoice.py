from fastapi import APIRouter, Body, Depends
from sqlalchemy.orm import Session

from dependencies.security import require_active_user, require_roles
from models.audit import AuditLogListResponse
from models.db import UserRecord
from models.invoice import (
    AssessmentPayload,
    GeolocationAutofillRequest,
    InvoiceCreate,
    InvoiceDetail,
    InvoiceListResponse,
    InvoiceMetadataUpdate,
    RiskLevel,
    WarehubSyncRequest,
    WarehubSyncResult,
)
from models.user import UserRole
from services.database import get_db
from services.audit import list_audit_logs
from services.invoice_service import (
    autofill_invoice_geolocation,
    create_manual_invoice,
    get_invoice_detail,
    list_invoices,
    sync_warehub_invoices,
    update_invoice_assessment,
    update_invoice_metadata,
)


router = APIRouter(prefix="/api/v1/invoices", tags=["Invoices"])


@router.get("", response_model=InvoiceListResponse)
def get_invoices(
    search: str | None = None,
    status: str | None = None,
    risk_level: RiskLevel | None = None,
    _: UserRecord = Depends(require_active_user),
    db: Session = Depends(get_db),
):
    return list_invoices(db, search=search, status=status, risk_level=risk_level)


@router.post("", response_model=InvoiceDetail, status_code=201)
def create_invoice(
    payload: InvoiceCreate,
    current_user: UserRecord = Depends(require_roles(UserRole.admin, UserRole.analyst, UserRole.reviewer)),
    db: Session = Depends(get_db),
):
    return create_manual_invoice(db, payload, actor=current_user)


@router.post("/sync/warehub", response_model=WarehubSyncResult)
def sync_from_warehub(
    payload: WarehubSyncRequest = Body(default=WarehubSyncRequest()),
    current_user: UserRecord = Depends(require_roles(UserRole.admin, UserRole.analyst)),
    db: Session = Depends(get_db),
):
    return sync_warehub_invoices(db, payload, actor=current_user)


@router.get("/{invoice_id}", response_model=InvoiceDetail)
def get_invoice(
    invoice_id: int,
    _: UserRecord = Depends(require_active_user),
    db: Session = Depends(get_db),
):
    return get_invoice_detail(db, invoice_id)


@router.put("/{invoice_id}", response_model=InvoiceDetail)
def update_invoice(
    invoice_id: int,
    payload: InvoiceMetadataUpdate,
    current_user: UserRecord = Depends(require_roles(UserRole.admin, UserRole.analyst, UserRole.reviewer)),
    db: Session = Depends(get_db),
):
    return update_invoice_metadata(db, invoice_id, payload, actor=current_user)


@router.put("/{invoice_id}/assessment", response_model=InvoiceDetail)
def update_assessment(
    invoice_id: int,
    payload: AssessmentPayload,
    current_user: UserRecord = Depends(require_roles(UserRole.admin, UserRole.analyst, UserRole.reviewer)),
    db: Session = Depends(get_db),
):
    return update_invoice_assessment(db, invoice_id, payload, actor=current_user)


@router.post("/{invoice_id}/geolocation/autofill", response_model=InvoiceDetail)
def autofill_geolocation(
    invoice_id: int,
    payload: GeolocationAutofillRequest = Body(default=GeolocationAutofillRequest()),
    current_user: UserRecord = Depends(require_roles(UserRole.admin, UserRole.analyst, UserRole.reviewer)),
    db: Session = Depends(get_db),
):
    return autofill_invoice_geolocation(db, invoice_id, payload=payload, actor=current_user)


@router.get("/{invoice_id}/audit-logs", response_model=AuditLogListResponse)
def get_invoice_audit_logs(
    invoice_id: int,
    _: UserRecord = Depends(require_active_user),
    db: Session = Depends(get_db),
):
    return list_audit_logs(db, entity_type="invoice", entity_id=invoice_id, limit=100)
