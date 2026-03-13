from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from dependencies.security import require_roles
from models.db import UserRecord
from models.user import UserCreate, UserPublic, UserRole, UserUpdate
from services.auth import create_user, serialize_user, update_user_record
from services.database import get_db


router = APIRouter(prefix="/api/v1/users", tags=["Users"])


@router.get("", response_model=list[UserPublic])
def list_users(
    _: UserRecord = Depends(require_roles(UserRole.admin)),
    db: Session = Depends(get_db),
):
    users = db.query(UserRecord).order_by(UserRecord.created_at.asc()).all()
    return [serialize_user(user) for user in users]


@router.post("", response_model=UserPublic, status_code=201)
def create_user_endpoint(
    payload: UserCreate,
    current_user: UserRecord = Depends(require_roles(UserRole.admin)),
    db: Session = Depends(get_db),
):
    user = create_user(db, payload, actor=current_user)
    return serialize_user(user)


@router.patch("/{user_id}", response_model=UserPublic)
def update_user_endpoint(
    user_id: int,
    payload: UserUpdate,
    current_user: UserRecord = Depends(require_roles(UserRole.admin)),
    db: Session = Depends(get_db),
):
    user = db.get(UserRecord, user_id)
    if user is None:
        from fastapi import HTTPException

        raise HTTPException(status_code=404, detail="User not found.")

    updated = update_user_record(
        db,
        user,
        full_name=payload.full_name,
        role=payload.role,
        is_active=payload.is_active,
        password=payload.password,
        actor=current_user,
    )
    return serialize_user(updated)
