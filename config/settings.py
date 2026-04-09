from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path
from typing import Annotated

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "Woodguard API"
    debug: bool = False
    api_prefix: str = "/api/v1"
    database_url: str = f"sqlite:///{(BASE_DIR / 'storage' / 'woodguard.db').as_posix()}"
    upload_dir: str = str(BASE_DIR / "storage" / "uploads")
    public_upload_prefix: str = "/uploads"
    auto_create_schema: bool = True
    warehub_base_url: str = "https://orderhub.automatonsoft.de/api/factories/invoices"
    warehub_account_id: int = 1
    warehub_timeout_seconds: float = 20.0
    geocoding_enabled: bool = True
    geocoding_base_url: str = "https://nominatim.openstreetmap.org"
    geocoding_timeout_seconds: float = 8.0
    geocoding_user_agent: str = "woodguard/1.0 (local-development)"
    geocoding_contact_email: str | None = None
    cors_origins: Annotated[list[str], NoDecode] = Field(
        default_factory=lambda: [
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "http://localhost:8501",
            "http://127.0.0.1:8501",
        ]
    )
    default_company_name: str = "Unassigned supplier"
    low_risk_threshold: float = 33.0
    medium_risk_threshold: float = 66.0
    jwt_secret_key: str = "change-me-in-production-woodguard-secret"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 720
    refresh_token_expire_days: int = 30
    auto_seed_admin: bool = True
    bootstrap_admin_username: str = "admin"
    bootstrap_admin_email: str = "admin@woodguard.local"
    bootstrap_admin_password: str = "woodguard123"
    bootstrap_admin_full_name: str = "Woodguard Admin"
    storage_backend: str = "local"
    s3_endpoint_url: str | None = None
    s3_region_name: str = "us-east-1"
    s3_bucket_name: str | None = None
    s3_access_key_id: str | None = None
    s3_secret_access_key: str | None = None
    s3_public_base_url: str | None = None
    s3_key_prefix: str = "woodguard"
    s3_presign_expire_seconds: int = 3600

    @field_validator("debug", mode="before")
    @classmethod
    def parse_debug(cls, value: bool | str) -> bool | str:
        if isinstance(value, str):
            lowered = value.strip().lower()
            if lowered in {"1", "true", "yes", "on", "debug", "development"}:
                return True
            if lowered in {"0", "false", "no", "off", "release", "prod", "production"}:
                return False
        return value

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: list[str] | str) -> list[str]:
        if isinstance(value, str):
            stripped = value.strip()
            if not stripped:
                return []
            if stripped.startswith("["):
                parsed = json.loads(stripped)
                return [str(item) for item in parsed]
            return [item.strip() for item in stripped.split(",") if item.strip()]
        return value

    @field_validator("upload_dir", mode="before")
    @classmethod
    def normalize_upload_dir(cls, value: str) -> str:
        path = Path(value)
        if path.is_absolute():
            return str(path)
        return str((BASE_DIR / path).resolve())


@lru_cache
def get_settings() -> Settings:
    return Settings()
