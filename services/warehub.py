from __future__ import annotations

import httpx

from config.settings import get_settings
from models.invoice import WarehubFactoriesResponse, WarehubInvoiceItem


class WarehubServiceError(RuntimeError):
    pass


class WarehubClient:
    def __init__(self) -> None:
        self.settings = get_settings()

    def _build_url(self, account_id: int) -> str:
        raw_url = self.settings.warehub_base_url.strip()
        normalized = raw_url.rstrip("/")
        if "{account_id}" in raw_url:
            return raw_url.format(account_id=account_id)
        if normalized.endswith("/api/public/invoices"):
            return f"{normalized}/{account_id}/"
        return raw_url

    def fetch_invoices(self, account_id: int, limit: int | None = None) -> list[WarehubInvoiceItem]:
        url = self._build_url(account_id)
        try:
            response = httpx.get(
                url,
                timeout=self.settings.warehub_timeout_seconds,
                headers={"Accept": "application/json"},
                follow_redirects=True,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise WarehubServiceError(f"Warehub request failed: {exc}") from exc

        payload = response.json()
        if isinstance(payload, list):
            items = [WarehubInvoiceItem.model_validate(item) for item in payload]
            return items[:limit] if limit else items

        if not isinstance(payload, dict):
            raise WarehubServiceError("Unexpected Warehub payload. Expected a factories object or a list of invoices.")

        factories = WarehubFactoriesResponse.model_validate(payload)
        items: list[WarehubInvoiceItem] = []
        for factory in factories.factories:
            for invoice in factory.invoices:
                items.append(
                    invoice.model_copy(
                        update={
                            "factory_id": factory.id,
                            "factory_name": factory.name,
                            "factory_email": factory.email,
                            "factory_contact_person": factory.contact_person,
                            "factory_phone": factory.phone,
                            "factory_address": factory.address,
                            "factory_country_code": factory.country.code if factory.country else None,
                            "factory_country_name": factory.country.name if factory.country else None,
                        }
                    )
                )

        return items[:limit] if limit else items
