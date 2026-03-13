from fastapi import APIRouter


router = APIRouter(prefix="/api/v1", tags=["System"])


@router.get("/health")
def healthcheck():
    return {"status": "ok", "service": "woodguard-api"}
