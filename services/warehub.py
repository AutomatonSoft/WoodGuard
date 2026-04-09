from __future__ import annotations

import httpx
from pydantic import ValidationError

from config.settings import get_settings
<<<<<<< HEAD
from models.invoice import (
    WarehubFactoriesPayload,
    WarehubFactoryPayload,
    WarehubInvoiceItem,
)
=======
from models.invoice import WarehubFactoriesResponse, WarehubInvoiceItem
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742


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
<<<<<<< HEAD
        url, params = self._build_request(account_id)
=======
        url = self._build_url(account_id)
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
        try:
            response = httpx.get(
                url,
                params=params,
                timeout=self.settings.warehub_timeout_seconds,
                headers={"Accept": "application/json"},
                follow_redirects=True,
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise WarehubServiceError(f"Warehub request failed: {exc}") from exc

        payload = response.json()
<<<<<<< HEAD
        try:
            if isinstance(payload, list):
                items = [WarehubInvoiceItem.model_validate(item) for item in payload]
            elif isinstance(payload, dict):
                items = self._flatten_factory_payload(payload)
            else:
                raise WarehubServiceError("Unexpected Warehub payload. Expected invoices or factories feed.")
        except ValidationError as exc:
            raise WarehubServiceError(f"Unexpected Warehub payload shape: {exc}") from exc
=======
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
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742

        return items[:limit] if limit else items

    def _build_request(self, account_id: int) -> tuple[str, dict[str, str] | None]:
        base_url = self.settings.warehub_base_url.rstrip("/")
        if base_url.endswith("/api/public/invoices"):
            return f"{base_url}/{account_id}/", None
        return f"{base_url}/", {"account_id": str(account_id)}

    def _flatten_factory_payload(self, payload: dict) -> list[WarehubInvoiceItem]:
        factories = WarehubFactoriesPayload.model_validate(payload)
        items: list[WarehubInvoiceItem] = []
        for factory in factories.factories:
            items.extend(self._flatten_factory(factory))
        return items

    def _flatten_factory(self, factory: WarehubFactoryPayload) -> list[WarehubInvoiceItem]:
        country_code = factory.country.code if factory.country else None
        country_name = factory.country.name if factory.country else None
        factory_payload = factory.model_dump(mode="json", exclude={"invoices"})

        flattened: list[WarehubInvoiceItem] = []
        for invoice in factory.invoices:
            order = invoice.order
            employee = invoice.employee
            flattened.append(
                WarehubInvoiceItem(
                    id=invoice.id,
                    invoice_number=invoice.invoice_number,
                    balance=invoice.balance,
                    total_paid=invoice.total_paid,
                    remaining_amount=invoice.remaining_amount,
                    status=invoice.status,
                    status_display=invoice.status_display,
                    created_at=invoice.created_at,
                    updated_at=invoice.updated_at,
                    due_date=invoice.due_date,
                    notes=invoice.notes,
                    factory_id=factory.id,
                    factory_name=factory.name,
                    factory_email=factory.email,
                    factory_contact_person=factory.contact_person,
                    factory_phone=factory.phone,
                    factory_address=factory.address,
                    factory_country_code=country_code,
                    factory_country_name=country_name,
                    order_id=order.id if order else None,
                    order_title=order.title if order else None,
                    order_status=order.status if order else None,
                    employee_id=employee.id if employee else None,
                    employee_username=employee.username if employee else None,
                    employee_full_name=employee.full_name if employee else None,
                    raw_payload={
                        "factory": factory_payload,
                        "invoice": invoice.model_dump(mode="json"),
                    },
                )
            )
        return flattened
