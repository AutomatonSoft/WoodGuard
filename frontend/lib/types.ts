export type RiskLevel = "low" | "medium" | "high";
export type DocumentStatus = "missing" | "uploaded" | "verified";
export type ComplianceChoice = "yes" | "no" | "unknown";

export interface CountryProfile {
  code: string;
  name: string;
  is_eu: boolean;
  base_risk: number;
}

export interface Evidence {
  status: DocumentStatus;
  memo: string | null;
  files: string[];
}

export interface AssessmentPayload {
  certificate: Evidence;
  location_pictures: Evidence;
  notice: Evidence;
  transport_papers: Evidence;
  geolocation_screenshot: Evidence;
  others: Evidence;
  wood_species: string[];
  material_types: string[];
  wood_specification_memo: string | null;
  country_of_origin: string | null;
  quantity: number | null;
  quantity_unit: string | null;
  slice_count: number | null;
  area_square_meters: number | null;
  delivery_date: string | null;
  child_labor_ok: ComplianceChoice;
  human_rights_ok: ComplianceChoice;
  geolocation_source_text: string | null;
  geolocation_latitude: number | null;
  geolocation_longitude: number | null;
  personal_risk_level: RiskLevel | null;
  risk_reason: string | null;
  last_reviewed_at: string | null;
}

export interface RiskBreakdownItem {
  key: string;
  label: string;
  weight: number;
  completed: boolean;
  awarded_points: number;
}

export interface RiskSummary {
  coverage_score: number;
  coverage_total: number;
  coverage_percent: number;
  penalty_points: number;
  risk_score: number;
  risk_percent: number;
  risk_level: RiskLevel;
  blockers: string[];
  missing_sections: string[];
  breakdown: RiskBreakdownItem[];
}

export interface InvoiceSummary {
  id: number;
  warehub_id: number | null;
  source: "warehub" | "manual";
  invoice_number: string;
  company_name: string | null;
  company_country: string | null;
  company_country_name: string | null;
  company_is_eu: boolean;
  amount: number;
  total_paid: number;
  remaining_amount: number;
  status: string;
  invoice_date: string | null;
  due_date: string | null;
  seller_name: string | null;
  synced_at: string | null;
  risk: RiskSummary;
}

export interface InvoiceDetail extends InvoiceSummary {
  production_date: string | null;
  import_date: string | null;
  notes: string | null;
  seller_address: string | null;
  seller_phone: string | null;
  seller_email: string | null;
  seller_website: string | null;
  seller_contact_person: string | null;
  seller_geolocation_label: string | null;
  seller_latitude: number | null;
  seller_longitude: number | null;
  assessment: AssessmentPayload;
  raw_payload: Record<string, unknown>;
}

export interface InvoiceListResponse {
  items: InvoiceSummary[];
  total: number;
}

export interface SupplierSummary {
  name: string;
  country: string | null;
  email: string | null;
  invoice_count: number;
  high_risk_count: number;
  total_amount: number;
  remaining_amount: number;
}

export interface DashboardMetrics {
  total_invoices: number;
  paid_invoices: number;
  open_invoices: number;
  low_risk_count: number;
  medium_risk_count: number;
  high_risk_count: number;
  non_eu_suppliers: number;
  open_exposure: number;
  average_coverage: number;
  latest_sync_at: string | null;
  suppliers: SupplierSummary[];
}

export interface ReferenceOptions {
  countries: CountryProfile[];
  wood_species: string[];
  material_types: string[];
  document_statuses: DocumentStatus[];
  risk_levels: RiskLevel[];
  compliance_choices: ComplianceChoice[];
}

export interface ReverseGeocodeResult {
  latitude: number;
  longitude: number;
  display_name: string;
  provider: string;
}

export interface UploadResponse {
  filename: string;
  url: string;
  content_type: string | null;
  size_bytes: number;
  storage_backend: string;
  object_key: string | null;
}

export interface UserPublic {
  id: number;
  username: string;
  email: string;
  full_name: string | null;
  role: "admin" | "analyst" | "reviewer" | "viewer";
  is_active: boolean;
  created_at: string;
}

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: "bearer";
  expires_in: number;
  refresh_expires_in: number;
  user: UserPublic;
}

export interface AuditLogEntry {
  id: number;
  actor_user_id: number | null;
  actor_username: string | null;
  actor_role: string | null;
  action: string;
  entity_type: string;
  entity_id: string | null;
  summary: string | null;
  payload: Record<string, unknown>;
  created_at: string;
}

export interface AuditLogListResponse {
  items: AuditLogEntry[];
  total: number;
}
