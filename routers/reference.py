from fastapi import APIRouter
from fastapi import Depends
from fastapi import HTTPException
from fastapi import Query

from dependencies.security import require_active_user
from models.db import UserRecord
from models.invoice import ReferenceOptions
from models.invoice import ReverseGeocodeResponse
from services.geocoding import GeocodingClient
from services.invoice_service import build_reference_options


router = APIRouter(prefix="/api/v1/reference", tags=["Reference"])


@router.get("/options", response_model=ReferenceOptions)
def get_reference_options(_: UserRecord = Depends(require_active_user)):
    return build_reference_options()


@router.get("/reverse-geocode", response_model=ReverseGeocodeResponse)
def reverse_geocode_coordinates(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    _: UserRecord = Depends(require_active_user),
):
    result = GeocodingClient().reverse_geocode(latitude, longitude)
    if result is None:
        raise HTTPException(status_code=422, detail="Could not determine address for these coordinates.")

    return ReverseGeocodeResponse(
        latitude=result.latitude,
        longitude=result.longitude,
        display_name=result.display_name,
        provider=result.provider,
    )
