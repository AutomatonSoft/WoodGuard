from __future__ import annotations

import httpx

from config.settings import get_settings
from models.invoice import WarehubInvoiceItem


class WarehubServiceError(RuntimeError):
    pass


class WarehubClient:
    def __init__(self) -> None:
        self.settings = get_settings()

    def fetch_invoices(self, account_id: int, limit: int | None = None) -> list[WarehubInvoiceItem]:
        url = f"{self.settings.warehub_base_url.rstrip('/')}/{account_id}/"
        try:
            response = httpx.get(
                url,
                timeout=self.settings.warehub_timeout_seconds,
                headers={"Accept": "application/json"},
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise WarehubServiceError(f"Warehub request failed: {exc}") from exc

        payload = response.json()
        if not isinstance(payload, list):
            raise WarehubServiceError("Unexpected Warehub payload. Expected a list of invoices.")

        items = [WarehubInvoiceItem.model_validate(item) for item in payload]
        return items[:limit] if limit else items
