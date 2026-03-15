from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from config.settings import get_settings
from models.country import list_countries, normalize_country_code, resolve_country
from models.db import InvoiceRecord, UserRecord
from models.invoice import (
    AssessmentPayload,
    ComplianceChoice,
    DashboardMetrics,
    DocumentStatus,
    GeolocationAutofillRequest,
    InvoiceCreate,
    InvoiceDetail,
    InvoiceListResponse,
    InvoiceMetadataUpdate,
    InvoiceSource,
    InvoiceSummary,
    MaterialType,
    ReferenceOptions,
    RiskLevel,
    RiskSummary,
    SupplierSummary,
    WarehubSyncRequest,
    WarehubSyncResult,
    WoodSpecies,
)
from services.risk import calculate_risk
from services.warehub import WarehubClient
from services.audit import log_audit_event
from services.geocoding import GeocodingClient


settings = get_settings()


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


def _default_assessment() -> AssessmentPayload:
    return AssessmentPayload()


def _assessment_from_record(record: InvoiceRecord) -> AssessmentPayload:
    return AssessmentPayload.model_validate(record.assessment_payload or {})


def _serialize_record(record: InvoiceRecord) -> InvoiceDetail:
    assessment = _assessment_from_record(record)
    risk = calculate_risk(assessment, record.company_country)
    country = resolve_country(record.company_country)
    record.company_country_name = country.name if country else record.company_country_name
    record.company_is_eu = country.is_eu if country else False
    record.risk_payload = risk.model_dump(mode="json")

    return InvoiceDetail(
        id=record.id,
        warehub_id=record.warehub_id,
        source=InvoiceSource(record.source),
        invoice_number=record.invoice_number,
        company_name=record.company_name,
        company_country=record.company_country,
        company_country_name=record.company_country_name,
        company_is_eu=record.company_is_eu,
        amount=round(record.amount or 0.0, 2),
        total_paid=round(record.total_paid or 0.0, 2),
        remaining_amount=round(record.remaining_amount or 0.0, 2),
        status=record.status,
        invoice_date=record.invoice_date,
        production_date=record.production_date,
        import_date=record.import_date,
        due_date=record.due_date,
        notes=record.notes,
        seller_name=record.seller_name,
        seller_address=record.seller_address,
        seller_phone=record.seller_phone,
        seller_email=record.seller_email,
        seller_website=record.seller_website,
        seller_contact_person=record.seller_contact_person,
        seller_geolocation_label=record.seller_geolocation_label,
        seller_latitude=record.seller_latitude,
        seller_longitude=record.seller_longitude,
        synced_at=record.synced_at,
        assessment=assessment,
        risk=risk,
        raw_payload=record.raw_payload or {},
    )


def _summary_from_record(record: InvoiceRecord) -> InvoiceSummary:
    detail = _serialize_record(record)
    return InvoiceSummary.model_validate(detail.model_dump())


def _apply_country(record: InvoiceRecord, raw_country: str | None) -> None:
    normalized = normalize_country_code(raw_country)
    record.company_country = normalized
    country = resolve_country(normalized)
    record.company_country_name = country.name if country else raw_country
    record.company_is_eu = country.is_eu if country else False


def _apply_metadata(record: InvoiceRecord, payload: InvoiceMetadataUpdate) -> None:
    changes = payload.model_dump(exclude_unset=True)
    if "company_country" in changes:
        _apply_country(record, changes.pop("company_country"))

    status = changes.pop("status", None)
    if status is not None:
        record.status = status.value

    for field, value in changes.items():
        setattr(record, field, value)

    if not record.company_name:
        record.company_name = settings.default_company_name


def _refresh_risk(record: InvoiceRecord) -> None:
    assessment = _assessment_from_record(record)
    record.risk_payload = calculate_risk(assessment, record.company_country).model_dump(mode="json")


def _build_geolocation_query(*parts: str | None) -> str | None:
    normalized_parts: list[str] = []
    for value in parts:
        trimmed = (value or "").strip()
        if trimmed and trimmed not in normalized_parts:
            normalized_parts.append(trimmed)

    return ", ".join(normalized_parts) if normalized_parts else None


def _meaningful_company_name(value: str | None) -> str | None:
    trimmed = (value or "").strip()
    if not trimmed:
        return None
    if trimmed.casefold() == settings.default_company_name.casefold():
        return None
    return trimmed


def _autofill_geolocation(record: InvoiceRecord, *, force: bool = False) -> None:
    geocoder = GeocodingClient()
    assessment = _assessment_from_record(record)
    assessment_changed = False

    seller_query = _build_geolocation_query(
        record.seller_geolocation_label,
        record.seller_address,
        record.seller_name,
        _meaningful_company_name(record.company_name),
        record.company_country_name or record.company_country,
    )
    seller_coordinates_missing = record.seller_latitude is None or record.seller_longitude is None
    if (force or seller_coordinates_missing) and seller_query:
        seller_result = geocoder.geocode(seller_query)
        if seller_result is not None:
            record.seller_latitude = seller_result.latitude
            record.seller_longitude = seller_result.longitude
            if not (record.seller_geolocation_label or "").strip():
                record.seller_geolocation_label = seller_result.display_name

    assessment_coordinates_missing = assessment.geolocation_latitude is None or assessment.geolocation_longitude is None
    if force or assessment_coordinates_missing:
        if record.seller_latitude is not None and record.seller_longitude is not None:
            assessment.geolocation_latitude = record.seller_latitude
            assessment.geolocation_longitude = record.seller_longitude
            if not (assessment.geolocation_source_text or "").strip():
                assessment.geolocation_source_text = record.seller_geolocation_label or seller_query
            assessment_changed = True
        else:
            assessment_query = _build_geolocation_query(
                assessment.geolocation_source_text,
                record.seller_geolocation_label,
                record.seller_address,
                record.seller_name,
                _meaningful_company_name(record.company_name),
                record.company_country_name or record.company_country,
            )
            if assessment_query:
                assessment_result = geocoder.geocode(assessment_query)
                if assessment_result is not None:
                    assessment.geolocation_latitude = assessment_result.latitude
                    assessment.geolocation_longitude = assessment_result.longitude
                    if not (assessment.geolocation_source_text or "").strip():
                        assessment.geolocation_source_text = assessment_result.display_name
                    if not (record.seller_geolocation_label or "").strip():
                        record.seller_geolocation_label = assessment_result.display_name
                    assessment_changed = True

    if assessment_changed:
        record.assessment_payload = assessment.model_dump(mode="json")


def autofill_invoice_geolocation(
    db: Session,
    invoice_id: int,
    *,
    payload: GeolocationAutofillRequest | None = None,
    actor: UserRecord | None = None,
) -> InvoiceDetail:
    record = get_invoice_or_404(db, invoice_id)
    if payload is not None:
        changes = payload.model_dump(exclude_unset=True, mode="json")
        if "company_country" in changes:
            _apply_country(record, changes.pop("company_country"))

        geolocation_source_text = changes.pop("geolocation_source_text", None)
        for field, value in changes.items():
            setattr(record, field, value)

        if geolocation_source_text is not None:
            assessment = _assessment_from_record(record)
            assessment.geolocation_source_text = geolocation_source_text
            record.assessment_payload = assessment.model_dump(mode="json")

    assessment_before = _assessment_from_record(record)
    has_existing_coordinates = (
        record.seller_latitude is not None
        and record.seller_longitude is not None
    ) or (
        assessment_before.geolocation_latitude is not None
        and assessment_before.geolocation_longitude is not None
    )
    has_lookup_source = _build_geolocation_query(
        assessment_before.geolocation_source_text,
        record.seller_geolocation_label,
        record.seller_address,
        record.seller_name,
        _meaningful_company_name(record.company_name),
    )

    if not has_existing_coordinates and not has_lookup_source:
        raise HTTPException(
            status_code=400,
            detail="Fill geolocation label, seller address or seller name first.",
        )

    _autofill_geolocation(record, force=True)
    assessment_after = _assessment_from_record(record)
    has_coordinates_after = (
        record.seller_latitude is not None
        and record.seller_longitude is not None
    ) or (
        assessment_after.geolocation_latitude is not None
        and assessment_after.geolocation_longitude is not None
    )

    if not has_coordinates_after:
        raise HTTPException(
            status_code=422,
            detail="Geolocation could not be determined from the current data.",
        )

    _refresh_risk(record)
    db.add(record)
    db.commit()
    db.refresh(record)
    log_audit_event(
        db,
        action="invoice.geolocation.autofill",
        entity_type="invoice",
        entity_id=record.id,
        summary=f"Invoice {record.invoice_number} geolocation auto-filled.",
        payload={
            "seller_latitude": record.seller_latitude,
            "seller_longitude": record.seller_longitude,
        },
        actor=actor,
    )
    return _serialize_record(record)


def list_invoices(
    db: Session,
    search: str | None = None,
    status: str | None = None,
    risk_level: RiskLevel | None = None,
) -> InvoiceListResponse:
    query = db.query(InvoiceRecord)
    if search:
        pattern = f"%{search.strip()}%"
        query = query.filter(
            or_(
                InvoiceRecord.invoice_number.ilike(pattern),
                InvoiceRecord.company_name.ilike(pattern),
                InvoiceRecord.seller_name.ilike(pattern),
            )
        )
    if status:
        query = query.filter(InvoiceRecord.status == status)

    records = query.order_by(InvoiceRecord.id.desc()).all()
    items = [_summary_from_record(record) for record in records]
    if risk_level:
        items = [item for item in items if item.risk.risk_level == risk_level]
    db.commit()
    return InvoiceListResponse(items=items, total=len(items))


def get_invoice_or_404(db: Session, invoice_id: int) -> InvoiceRecord:
    record = db.get(InvoiceRecord, invoice_id)
    if record is None:
        raise HTTPException(status_code=404, detail="Invoice not found.")
    return record


def get_invoice_detail(db: Session, invoice_id: int) -> InvoiceDetail:
    record = get_invoice_or_404(db, invoice_id)
    detail = _serialize_record(record)
    db.commit()
    return detail


def create_manual_invoice(
    db: Session,
    payload: InvoiceCreate,
    *,
    actor: UserRecord | None = None,
) -> InvoiceDetail:
    record = InvoiceRecord(
        source=InvoiceSource.manual.value,
        invoice_number=payload.invoice_number,
        company_name=payload.company_name or settings.default_company_name,
        amount=payload.amount,
        total_paid=payload.total_paid or 0.0,
        remaining_amount=payload.remaining_amount if payload.remaining_amount is not None else payload.amount,
        status=payload.status.value,
        assessment_payload=_default_assessment().model_dump(mode="json"),
        risk_payload={},
        raw_payload={},
    )
    _apply_metadata(record, payload)
    _autofill_geolocation(record)
    _refresh_risk(record)
    db.add(record)
    db.commit()
    db.refresh(record)
    log_audit_event(
        db,
        action="invoice.create",
        entity_type="invoice",
        entity_id=record.id,
        summary=f"Manual invoice {record.invoice_number} created.",
        payload={"source": record.source, "company_name": record.company_name, "amount": record.amount},
        actor=actor,
    )
    return _serialize_record(record)


def update_invoice_metadata(
    db: Session,
    invoice_id: int,
    payload: InvoiceMetadataUpdate,
    *,
    actor: UserRecord | None = None,
) -> InvoiceDetail:
    record = get_invoice_or_404(db, invoice_id)
    changes = payload.model_dump(exclude_unset=True, mode="json")
    _apply_metadata(record, payload)
    _autofill_geolocation(record)
    _refresh_risk(record)
    db.add(record)
    db.commit()
    db.refresh(record)
    log_audit_event(
        db,
        action="invoice.metadata.update",
        entity_type="invoice",
        entity_id=record.id,
        summary=f"Invoice {record.invoice_number} metadata updated.",
        payload=changes,
        actor=actor,
    )
    return _serialize_record(record)


def update_invoice_assessment(
    db: Session,
    invoice_id: int,
    payload: AssessmentPayload,
    *,
    actor: UserRecord | None = None,
) -> InvoiceDetail:
    record = get_invoice_or_404(db, invoice_id)
    assessment = payload.model_copy(update={"last_reviewed_at": _now_utc()})
    record.assessment_payload = assessment.model_dump(mode="json")
    _autofill_geolocation(record)
    _refresh_risk(record)
    db.add(record)
    db.commit()
    db.refresh(record)
    log_audit_event(
        db,
        action="invoice.assessment.update",
        entity_type="invoice",
        entity_id=record.id,
        summary=f"Invoice {record.invoice_number} assessment updated.",
        payload={
            "risk_level": record.risk_payload.get("risk_level"),
            "coverage_percent": record.risk_payload.get("coverage_percent"),
        },
        actor=actor,
    )
    return _serialize_record(record)


def sync_warehub_invoices(
    db: Session,
    request: WarehubSyncRequest,
    *,
    actor: UserRecord | None = None,
) -> WarehubSyncResult:
    account_id = request.account_id or settings.warehub_account_id
    synced_at = _now_utc()
    imported = 0
    updated = 0

    items = WarehubClient().fetch_invoices(account_id=account_id, limit=request.limit)
    for item in items:
        record = db.query(InvoiceRecord).filter(InvoiceRecord.warehub_id == item.id).one_or_none()
        if record is None:
            record = InvoiceRecord(
                warehub_id=item.id,
                source=InvoiceSource.warehub.value,
                assessment_payload=_default_assessment().model_dump(mode="json"),
            )
            db.add(record)
            imported += 1
        else:
            updated += 1

        record.invoice_number = item.invoice_number
        record.amount = item.balance
        record.total_paid = item.total_paid
        record.remaining_amount = item.remaining_amount
        record.status = item.status or "unknown"
        record.notes = item.notes or record.notes or ""
        record.due_date = item.due_date
        record.warehub_created_at = item.created_at
        record.warehub_updated_at = item.updated_at
        record.synced_at = synced_at
        record.raw_payload = item.model_dump(mode="json")
        if not record.company_name:
            record.company_name = settings.default_company_name
        if record.company_country:
            _apply_country(record, record.company_country)
        _autofill_geolocation(record)
        _refresh_risk(record)

    db.commit()
    result = WarehubSyncResult(
        account_id=account_id,
        total_received=len(items),
        imported=imported,
        updated=updated,
        synced_at=synced_at,
    )
    log_audit_event(
        db,
        action="invoice.sync.warehub",
        entity_type="integration",
        entity_id=account_id,
        summary=f"Warehub sync completed for account {account_id}.",
        payload=result.model_dump(mode="json"),
        actor=actor,
    )
    return result


def build_dashboard_metrics(db: Session) -> DashboardMetrics:
    records = db.query(InvoiceRecord).order_by(InvoiceRecord.id.desc()).all()
    summaries = [_summary_from_record(record) for record in records]

    suppliers: dict[str, SupplierSummary] = {}
    low_risk_count = 0
    medium_risk_count = 0
    high_risk_count = 0
    coverage_total = 0.0
    latest_sync_at = None

    for item in summaries:
        if item.risk.risk_level == RiskLevel.low:
            low_risk_count += 1
        elif item.risk.risk_level == RiskLevel.medium:
            medium_risk_count += 1
        else:
            high_risk_count += 1

        coverage_total += item.risk.coverage_percent
        if item.synced_at and (latest_sync_at is None or item.synced_at > latest_sync_at):
            latest_sync_at = item.synced_at

        supplier_name = item.company_name or item.seller_name or settings.default_company_name
        supplier = suppliers.get(supplier_name)
        if supplier is None:
            supplier = SupplierSummary(
                name=supplier_name,
                country=item.company_country_name or item.company_country,
                invoice_count=0,
                high_risk_count=0,
                total_amount=0.0,
                remaining_amount=0.0,
            )
            suppliers[supplier_name] = supplier

        supplier.invoice_count += 1
        supplier.total_amount += item.amount
        supplier.remaining_amount += item.remaining_amount
        if item.risk.risk_level == RiskLevel.high:
            supplier.high_risk_count += 1

    open_invoices = len([item for item in summaries if item.status != "paid"])
    paid_invoices = len([item for item in summaries if item.status == "paid"])
    open_exposure = round(sum(item.remaining_amount for item in summaries), 2)
    average_coverage = round((coverage_total / len(summaries)) if summaries else 0.0, 1)
    non_eu_suppliers = len(
        {
            item.company_name or item.seller_name or settings.default_company_name
            for item in summaries
            if not item.company_is_eu
        }
    )

    supplier_list = sorted(
        suppliers.values(),
        key=lambda supplier: (-supplier.high_risk_count, -supplier.invoice_count, supplier.name),
    )

    db.commit()
    return DashboardMetrics(
        total_invoices=len(summaries),
        paid_invoices=paid_invoices,
        open_invoices=open_invoices,
        low_risk_count=low_risk_count,
        medium_risk_count=medium_risk_count,
        high_risk_count=high_risk_count,
        non_eu_suppliers=non_eu_suppliers,
        open_exposure=open_exposure,
        average_coverage=average_coverage,
        latest_sync_at=latest_sync_at,
        suppliers=supplier_list[:12],
    )


def build_reference_options() -> ReferenceOptions:
    return ReferenceOptions(
        countries=list_countries(),
        wood_species=[item.value for item in WoodSpecies],
        material_types=[item.value for item in MaterialType],
        document_statuses=[item.value for item in DocumentStatus],
        risk_levels=[item.value for item in RiskLevel],
        compliance_choices=[item.value for item in ComplianceChoice],
    )
