from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from dependencies.security import require_active_user
from models.db import UserRecord
from models.invoice import DashboardMetrics
from services.database import get_db
from services.invoice_service import build_dashboard_metrics


router = APIRouter(prefix="/api/v1/dashboard", tags=["Dashboard"])


@router.get("/metrics", response_model=DashboardMetrics)
def get_dashboard_metrics(
    _: UserRecord = Depends(require_active_user),
    db: Session = Depends(get_db),
):
    return build_dashboard_metrics(db)
