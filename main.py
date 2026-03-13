from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config.settings import get_settings
from routers import assets, audit, auth, dashboard, invoice, reference, test, user
from services.auth import ensure_bootstrap_admin
from services.database import SessionLocal, init_db


settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    if settings.storage_backend == "local":
        Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
    init_db()
    with SessionLocal() as session:
        ensure_bootstrap_admin(session)
    yield


app = FastAPI(
    title=settings.app_name,
    description="Invoice due diligence workspace for Woodguard.",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if settings.storage_backend == "local":
    app.mount(
        settings.public_upload_prefix,
        StaticFiles(directory=settings.upload_dir),
        name="uploads",
    )

app.include_router(test.router)
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(audit.router)
app.include_router(reference.router)
app.include_router(dashboard.router)
app.include_router(assets.router)
app.include_router(invoice.router)
