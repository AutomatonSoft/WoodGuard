from __future__ import annotations

from datetime import date, datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field

from models.country import CountryProfile


class InvoiceSource(str, Enum):
    warehub = "warehub"
    manual = "manual"


class InvoiceStatus(str, Enum):
    pending = "pending"
    partial = "partial"
    paid = "paid"
    cancelled = "cancelled"
    draft = "draft"
    unknown = "unknown"


class DocumentStatus(str, Enum):
    missing = "missing"
    uploaded = "uploaded"
    verified = "verified"


class RiskLevel(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"


class ComplianceChoice(str, Enum):
    yes = "yes"
    no = "no"
    unknown = "unknown"


class MaterialType(str, Enum):
    solid_wood = "solid_wood"
    mdf = "mdf"
    hdf = "hdf"
    particle_board = "particle_board"
    plywood = "plywood"
    veneer = "veneer"
    other = "other"


class WoodSpecies(str, Enum):
    oak = "oak"
    beech = "beech"
    pine = "pine"
    spruce = "spruce"
    ash = "ash"
    maple = "maple"
    birch = "birch"
    walnut = "walnut"
    cherry = "cherry"
    mahogany = "mahogany"
    teak = "teak"


class Evidence(BaseModel):
    status: DocumentStatus = DocumentStatus.missing
    memo: str | None = None
    files: list[str] = Field(default_factory=list)


class AssessmentPayload(BaseModel):
    certificate: Evidence = Field(default_factory=Evidence)
    location_pictures: Evidence = Field(default_factory=Evidence)
    notice: Evidence = Field(default_factory=Evidence)
    transport_papers: Evidence = Field(default_factory=Evidence)
    geolocation_screenshot: Evidence = Field(default_factory=Evidence)
    others: Evidence = Field(default_factory=Evidence)
    wood_species: list[str] = Field(default_factory=list)
    material_types: list[str] = Field(default_factory=list)
    wood_specification_memo: str | None = None
    country_of_origin: str | None = None
    quantity: float | None = None
    quantity_unit: str | None = None
    slice_count: int | None = None
    area_square_meters: float | None = None
    delivery_date: date | None = None
    child_labor_ok: ComplianceChoice = ComplianceChoice.unknown
    human_rights_ok: ComplianceChoice = ComplianceChoice.unknown
    geolocation_source_text: str | None = None
    geolocation_latitude: float | None = None
    geolocation_longitude: float | None = None
    personal_risk_level: RiskLevel | None = None
    risk_reason: str | None = None
    last_reviewed_at: datetime | None = None


class RiskBreakdownItem(BaseModel):
    key: str
    label: str
    weight: int
    completed: bool
    awarded_points: int


class RiskSummary(BaseModel):
    coverage_score: int = 0
    coverage_total: int = 0
    coverage_percent: float = 0.0
    penalty_points: int = 0
    risk_score: float = 100.0
    risk_percent: float = 100.0
    risk_level: RiskLevel = RiskLevel.high
    blockers: list[str] = Field(default_factory=list)
    missing_sections: list[str] = Field(default_factory=list)
    breakdown: list[RiskBreakdownItem] = Field(default_factory=list)


class InvoiceMetadataUpdate(BaseModel):
    company_name: str | None = None
    company_country: str | None = None
    invoice_date: date | None = None
    production_date: date | None = None
    import_date: date | None = None
    due_date: date | None = None
    amount: float | None = None
    total_paid: float | None = None
    remaining_amount: float | None = None
    status: InvoiceStatus | None = None
    notes: str | None = None
    seller_name: str | None = None
    seller_address: str | None = None
    seller_phone: str | None = None
    seller_email: str | None = None
    seller_website: str | None = None
    seller_contact_person: str | None = None
    seller_geolocation_label: str | None = None
    seller_latitude: float | None = None
    seller_longitude: float | None = None


class GeolocationAutofillRequest(BaseModel):
    company_name: str | None = None
    company_country: str | None = None
    seller_name: str | None = None
    seller_address: str | None = None
    seller_geolocation_label: str | None = None
    geolocation_source_text: str | None = None


class ReverseGeocodeResponse(BaseModel):
    latitude: float
    longitude: float
    display_name: str
    provider: str = "nominatim"


class InvoiceCreate(InvoiceMetadataUpdate):
    invoice_number: str
    amount: float = 0.0
    status: InvoiceStatus = InvoiceStatus.pending


<<<<<<< HEAD
class WarehubCountryItem(BaseModel):
=======
class WarehubCountry(BaseModel):
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
    id: int | None = None
    name: str | None = None
    code: str | None = None


<<<<<<< HEAD
class WarehubOrderItem(BaseModel):
=======
class WarehubOrder(BaseModel):
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
    id: int | None = None
    title: str | None = None
    status: str | None = None
    status_display: str | None = None


<<<<<<< HEAD
class WarehubEmployeeItem(BaseModel):
=======
class WarehubEmployee(BaseModel):
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
    id: int | None = None
    username: str | None = None
    full_name: str | None = None


<<<<<<< HEAD
class WarehubFactoryInvoicePayload(BaseModel):
    id: int
    invoice_number: str
    balance: float
    total_paid: float
    remaining_amount: float
    status: str
    status_display: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    due_date: date | None = None
    notes: str | None = None
    order: WarehubOrderItem | None = None
    employee: WarehubEmployeeItem | None = None


class WarehubFactoryPayload(BaseModel):
    id: int
    name: str | None = None
    email: str | None = None
    contact_person: str | None = None
    phone: str | None = None
    address: str | None = None
    country: WarehubCountryItem | None = None
    invoices_count: int | None = None
    invoices: list[WarehubFactoryInvoicePayload] = Field(default_factory=list)


class WarehubFactoriesPayload(BaseModel):
    factories: list[WarehubFactoryPayload]


=======
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
class WarehubInvoiceItem(BaseModel):
    id: int
    invoice_number: str
    balance: float
    total_paid: float
    remaining_amount: float
    status: str
    status_display: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    due_date: date | None = None
    notes: str | None = None
<<<<<<< HEAD
=======
    status_display: str | None = None
    order: WarehubOrder | None = None
    employee: WarehubEmployee | None = None
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
    factory_id: int | None = None
    factory_name: str | None = None
    factory_email: str | None = None
    factory_contact_person: str | None = None
    factory_phone: str | None = None
    factory_address: str | None = None
    factory_country_code: str | None = None
    factory_country_name: str | None = None
<<<<<<< HEAD
    order_id: int | None = None
    order_title: str | None = None
    order_status: str | None = None
    employee_id: int | None = None
    employee_username: str | None = None
    employee_full_name: str | None = None
    raw_payload: dict = Field(default_factory=dict)
=======


class WarehubFactoryInvoices(BaseModel):
    id: int
    name: str
    email: str | None = None
    contact_person: str | None = None
    phone: str | None = None
    address: str | None = None
    country: WarehubCountry | None = None
    invoices_count: int = 0
    invoices: list[WarehubInvoiceItem] = Field(default_factory=list)


class WarehubFactoriesResponse(BaseModel):
    factories: list[WarehubFactoryInvoices] = Field(default_factory=list)
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742


class WarehubSyncRequest(BaseModel):
    account_id: int | None = None
    limit: int | None = Field(default=None, ge=1, le=500)


class WarehubSyncResult(BaseModel):
    account_id: int
    total_received: int
    imported: int
    updated: int
    synced_at: datetime


class SupplierSummary(BaseModel):
    name: str
    country: str | None = None
    email: str | None = None
    invoice_count: int
    high_risk_count: int
    total_amount: float
    remaining_amount: float


class InvoiceSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    warehub_id: int | None = None
    source: InvoiceSource
    invoice_number: str
    company_name: str | None = None
    company_country: str | None = None
    company_country_name: str | None = None
    company_is_eu: bool = False
    amount: float
    total_paid: float
    remaining_amount: float
    status: str
    invoice_date: date | None = None
    due_date: date | None = None
    seller_name: str | None = None
    synced_at: datetime | None = None
    risk: RiskSummary


class InvoiceDetail(InvoiceSummary):
    production_date: date | None = None
    import_date: date | None = None
    notes: str | None = None
    seller_address: str | None = None
    seller_phone: str | None = None
    seller_email: str | None = None
    seller_website: str | None = None
    seller_contact_person: str | None = None
    seller_geolocation_label: str | None = None
    seller_latitude: float | None = None
    seller_longitude: float | None = None
    assessment: AssessmentPayload = Field(default_factory=AssessmentPayload)
    raw_payload: dict = Field(default_factory=dict)


class InvoiceListResponse(BaseModel):
    items: list[InvoiceSummary]
    total: int


class DashboardMetrics(BaseModel):
    total_invoices: int
    paid_invoices: int
    open_invoices: int
    low_risk_count: int
    medium_risk_count: int
    high_risk_count: int
    non_eu_suppliers: int
    open_exposure: float
    average_coverage: float
    latest_sync_at: datetime | None = None
    suppliers: list[SupplierSummary] = Field(default_factory=list)


class UploadResponse(BaseModel):
    filename: str
    url: str
    content_type: str | None = None
    size_bytes: int
    storage_backend: str = "local"
    object_key: str | None = None


class ReferenceOptions(BaseModel):
    countries: list[CountryProfile]
    wood_species: list[str]
    material_types: list[str]
    document_statuses: list[str]
    risk_levels: list[str]
    compliance_choices: list[str]
