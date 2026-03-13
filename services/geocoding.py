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
    provider: str = "nominatim"


class GeocodingClient:
    def __init__(self) -> None:
        self.settings = get_settings()

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
        if self.settings.geocoding_contact_email:
            params["email"] = self.settings.geocoding_contact_email

        headers = {
            "Accept": "application/json",
            "User-Agent": self.settings.geocoding_user_agent,
        }

        try:
            response = httpx.get(
                f"{self.settings.geocoding_base_url.rstrip('/')}/search",
                params=params,
                headers=headers,
                timeout=self.settings.geocoding_timeout_seconds,
            )
            response.raise_for_status()
        except httpx.HTTPError:
            return None

        payload = response.json()
        if not isinstance(payload, list) or not payload:
            return None

        item = payload[0]
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
        )
