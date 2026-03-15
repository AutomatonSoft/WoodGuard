from __future__ import annotations

from dataclasses import dataclass

import httpx

from config.settings import get_settings


@dataclass
class GeocodingResult:
    latitude: float
    longitude: float
    display_name: str
    query: str
    label: str | None = None
    provider: str = "nominatim"


class GeocodingClient:
    def __init__(self) -> None:
        self.settings = get_settings()

    def _headers(self) -> dict[str, str]:
        return {
            "Accept": "application/json",
            "User-Agent": self.settings.geocoding_user_agent,
        }

    def _request_json(self, path: str, params: dict[str, str | int | float]) -> object | None:
        if self.settings.geocoding_contact_email:
            params["email"] = self.settings.geocoding_contact_email

        try:
            response = httpx.get(
                f"{self.settings.geocoding_base_url.rstrip('/')}/{path.lstrip('/')}",
                params=params,
                headers=self._headers(),
                timeout=self.settings.geocoding_timeout_seconds,
            )
            response.raise_for_status()
        except httpx.HTTPError:
            return None

        return response.json()

    def _build_label(self, item: dict[str, object], fallback: str) -> str:
        name = item.get("name")
        if isinstance(name, str) and name.strip():
            return name.strip()

        address = item.get("address")
        if isinstance(address, dict):
            for key in (
                "amenity",
                "building",
                "road",
                "pedestrian",
                "neighbourhood",
                "suburb",
                "village",
                "town",
                "city",
                "county",
                "state",
                "country",
            ):
                value = address.get(key)
                if isinstance(value, str) and value.strip():
                    return value.strip()

        first_segment = fallback.split(",", 1)[0].strip()
        return first_segment or fallback

    def geocode(self, query: str | None) -> GeocodingResult | None:
        if not self.settings.geocoding_enabled:
            return None

        normalized_query = (query or "").strip()
        if not normalized_query:
            return None

        params: dict[str, str | int] = {
            "q": normalized_query,
            "format": "jsonv2",
            "limit": 1,
        }
        payload = self._request_json("/search", params)
        if not isinstance(payload, list) or not payload:
            return None

        item = payload[0]
        if not isinstance(item, dict):
            return None
        try:
            latitude = float(item["lat"])
            longitude = float(item["lon"])
        except (KeyError, TypeError, ValueError):
            return None

        display_name = str(item.get("display_name") or normalized_query)
        return GeocodingResult(
            latitude=latitude,
            longitude=longitude,
            display_name=display_name,
            query=normalized_query,
            label=self._build_label(item, display_name),
        )

    def reverse_geocode(self, latitude: float | None, longitude: float | None) -> GeocodingResult | None:
        if not self.settings.geocoding_enabled:
            return None
        if latitude is None or longitude is None:
            return None
        if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
            return None

        normalized_latitude = round(float(latitude), 6)
        normalized_longitude = round(float(longitude), 6)
        query = f"{normalized_latitude:.6f}, {normalized_longitude:.6f}"
        payload = self._request_json(
            "/reverse",
            {
                "lat": normalized_latitude,
                "lon": normalized_longitude,
                "format": "jsonv2",
                "zoom": 18,
                "addressdetails": 1,
            },
        )
        if not isinstance(payload, dict):
            return None

        try:
            resolved_latitude = float(payload.get("lat", normalized_latitude))
            resolved_longitude = float(payload.get("lon", normalized_longitude))
        except (TypeError, ValueError):
            resolved_latitude = normalized_latitude
            resolved_longitude = normalized_longitude

        display_name = str(payload.get("display_name") or query)
        return GeocodingResult(
            latitude=resolved_latitude,
            longitude=resolved_longitude,
            display_name=display_name,
            query=query,
            label=self._build_label(payload, display_name),
        )
