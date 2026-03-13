from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from dependencies.security import require_active_user
from models.user import LogoutRequest, RefreshTokenRequest, TokenResponse, UserLogin, UserPublic
from services.auth import login_user, refresh_user_session, revoke_refresh_token, serialize_user
from services.database import get_db


router = APIRouter(prefix="/api/v1/auth", tags=["Auth"])


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, request: Request, db: Session = Depends(get_db)):
    return login_user(db, payload.username, payload.password, user_agent=request.headers.get("user-agent"))


@router.post("/refresh", response_model=TokenResponse)
def refresh(payload: RefreshTokenRequest, request: Request, db: Session = Depends(get_db)):
    return refresh_user_session(db, payload, user_agent=request.headers.get("user-agent"))


@router.post("/logout", status_code=204)
def logout(payload: LogoutRequest, db: Session = Depends(get_db)):
    revoke_refresh_token(db, payload)
    return None


@router.get("/me", response_model=UserPublic)
def get_me(current_user=Depends(require_active_user)):
    return serialize_user(current_user)
