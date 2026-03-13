from __future__ import annotations

from collections.abc import Generator
from pathlib import Path

from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import Session, sessionmaker

from config.settings import get_settings
from models.db import Base


settings = get_settings()


def _build_connect_args(database_url: str) -> dict[str, bool]:
    if database_url.startswith("sqlite"):
        return {"check_same_thread": False}
    return {}


engine = create_engine(
    settings.database_url,
    echo=settings.debug,
    connect_args=_build_connect_args(settings.database_url),
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)
_bootstrap_verified = False


def init_db() -> None:
    if settings.database_url.startswith("sqlite:///"):
        db_file = Path(settings.database_url.removeprefix("sqlite:///"))
        db_file.parent.mkdir(parents=True, exist_ok=True)
    if settings.auto_create_schema:
        Base.metadata.create_all(bind=engine)


def get_db() -> Generator[Session, None, None]:
    global _bootstrap_verified
    db = SessionLocal()
    try:
        if not _bootstrap_verified:
            from services.auth import ensure_bootstrap_admin

            ensure_bootstrap_admin(db)
            if db.bind is not None and "users" in inspect(db.bind).get_table_names():
                _bootstrap_verified = True
        yield db
    finally:
        db.close()
