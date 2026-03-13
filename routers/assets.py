from fastapi import APIRouter, Depends, File, Form, UploadFile

from dependencies.security import require_roles
from models.db import UserRecord
from models.invoice import UploadResponse
from models.user import UserRole
from services.assets import save_upload
from services.audit import log_audit_event
from services.database import get_db
from sqlalchemy.orm import Session


router = APIRouter(prefix="/api/v1/uploads", tags=["Uploads"])


@router.post("", response_model=UploadResponse, status_code=201)
def upload_file(
    invoice_id: int | None = Form(default=None),
    section: str | None = Form(default=None),
    file: UploadFile = File(...),
    current_user: UserRecord = Depends(require_roles(UserRole.admin, UserRole.analyst, UserRole.reviewer)),
    db: Session = Depends(get_db),
):
    upload = save_upload(file, folder="invoices" if invoice_id else "uploads", invoice_id=invoice_id, section=section)
    log_audit_event(
        db,
        action="upload.create",
        entity_type="invoice" if invoice_id else "upload",
        entity_id=invoice_id or upload.object_key,
        summary=f"File {upload.filename} uploaded.",
        payload={"section": section, "url": upload.url, "storage_backend": upload.storage_backend},
        actor=current_user,
    )
    return upload
