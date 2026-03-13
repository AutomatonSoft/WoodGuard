from fastapi import APIRouter
from fastapi import Depends

from dependencies.security import require_active_user
from models.db import UserRecord
from models.invoice import ReferenceOptions
from services.invoice_service import build_reference_options


router = APIRouter(prefix="/api/v1/reference", tags=["Reference"])


@router.get("/options", response_model=ReferenceOptions)
def get_reference_options(_: UserRecord = Depends(require_active_user)):
    return build_reference_options()
