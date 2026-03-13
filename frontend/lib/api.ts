import type {
  AssessmentPayload,
  AuditLogListResponse,
  DashboardMetrics,
  InvoiceDetail,
  InvoiceListResponse,
  ReferenceOptions,
  TokenResponse,
  UploadResponse,
  UserPublic,
} from "./types";


const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000/api/v1";
export const API_ORIGIN = new URL(API_BASE).origin;
const ACCESS_TOKEN_STORAGE_KEY = "woodguard_access_token";
const REFRESH_TOKEN_STORAGE_KEY = "woodguard_refresh_token";


export interface InvoiceCreatePayload {
  invoice_number: string;
  company_name?: string | null;
  company_country?: string | null;
  amount?: number;
  status?: string;
}


export interface InvoiceMetadataPayload {
  company_name?: string | null;
  company_country?: string | null;
  invoice_date?: string | null;
  production_date?: string | null;
  import_date?: string | null;
  due_date?: string | null;
  amount?: number | null;
  total_paid?: number | null;
  remaining_amount?: number | null;
  status?: string | null;
  notes?: string | null;
  seller_name?: string | null;
  seller_address?: string | null;
  seller_phone?: string | null;
  seller_email?: string | null;
  seller_website?: string | null;
  seller_contact_person?: string | null;
  seller_geolocation_label?: string | null;
  seller_latitude?: number | null;
  seller_longitude?: number | null;
}


export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}


function isBrowser(): boolean {
  return typeof window !== "undefined";
}


export function getStoredToken(): string | null {
  return isBrowser() ? window.localStorage.getItem(ACCESS_TOKEN_STORAGE_KEY) : null;
}


export function getStoredRefreshToken(): string | null {
  return isBrowser() ? window.localStorage.getItem(REFRESH_TOKEN_STORAGE_KEY) : null;
}


export function storeTokens(accessToken: string | null, refreshToken: string | null): void {
  if (!isBrowser()) {
    return;
  }

  if (accessToken) {
    window.localStorage.setItem(ACCESS_TOKEN_STORAGE_KEY, accessToken);
  } else {
    window.localStorage.removeItem(ACCESS_TOKEN_STORAGE_KEY);
  }

  if (refreshToken) {
    window.localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, refreshToken);
  } else {
    window.localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY);
  }
}


let refreshPromise: Promise<TokenResponse | null> | null = null;


async function refreshSession(): Promise<TokenResponse | null> {
  const refreshToken = getStoredRefreshToken();
  if (!refreshToken) {
    storeTokens(null, null);
    return null;
  }
  if (refreshPromise) {
    return refreshPromise;
  }

  refreshPromise = fetch(`${API_BASE}/auth/refresh`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh_token: refreshToken }),
    cache: "no-store",
  })
    .then(async (response) => {
      if (!response.ok) {
        storeTokens(null, null);
        return null;
      }
      const payload = (await response.json()) as TokenResponse;
      storeTokens(payload.access_token, payload.refresh_token);
      return payload;
    })
    .finally(() => {
      refreshPromise = null;
    });

  return refreshPromise;
}


async function request<T>(path: string, init?: RequestInit, retry = true): Promise<T> {
  const headers = new Headers(init?.headers);
  const isFormData = init?.body instanceof FormData;
  if (!isFormData && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  const token = getStoredToken();
  if (token && !headers.has("Authorization")) {
    headers.set("Authorization", `Bearer ${token}`);
  }

  const response = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers,
    cache: "no-store",
  });

  if (response.status === 401 && retry && !path.startsWith("/auth/")) {
    const refreshed = await refreshSession();
    if (refreshed) {
      return request<T>(path, init, false);
    }
  }

  if (!response.ok) {
    const message = await response.text();
    if (response.status === 401) {
      storeTokens(null, null);
    }
    throw new ApiError(message || "Request failed.", response.status);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return (await response.json()) as T;
}


export async function login(username: string, password: string): Promise<TokenResponse> {
  const response = await request<TokenResponse>("/auth/login", {
    method: "POST",
    body: JSON.stringify({ username, password }),
  });
  storeTokens(response.access_token, response.refresh_token);
  return response;
}


export async function logout(): Promise<void> {
  const refreshToken = getStoredRefreshToken();
  if (refreshToken) {
    await request("/auth/logout", {
      method: "POST",
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
  }
  storeTokens(null, null);
}


export async function getMe(): Promise<UserPublic> {
  return request<UserPublic>("/auth/me");
}


export async function getMetrics(): Promise<DashboardMetrics> {
  return request<DashboardMetrics>("/dashboard/metrics");
}


export async function getReferenceOptions(): Promise<ReferenceOptions> {
  return request<ReferenceOptions>("/reference/options");
}


export async function getInvoices(): Promise<InvoiceListResponse> {
  return request<InvoiceListResponse>("/invoices");
}


export async function getInvoice(invoiceId: number): Promise<InvoiceDetail> {
  return request<InvoiceDetail>(`/invoices/${invoiceId}`);
}


export async function getInvoiceAuditLogs(invoiceId: number): Promise<AuditLogListResponse> {
  return request<AuditLogListResponse>(`/invoices/${invoiceId}/audit-logs`);
}


export async function syncWarehub(): Promise<void> {
  await request("/invoices/sync/warehub", {
    method: "POST",
    body: JSON.stringify({}),
  });
}


export async function createInvoice(payload: InvoiceCreatePayload): Promise<InvoiceDetail> {
  return request<InvoiceDetail>("/invoices", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}


export async function updateInvoice(
  invoiceId: number,
  payload: InvoiceMetadataPayload,
): Promise<InvoiceDetail> {
  return request<InvoiceDetail>(`/invoices/${invoiceId}`, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}


export async function updateAssessment(
  invoiceId: number,
  payload: AssessmentPayload,
): Promise<InvoiceDetail> {
  return request<InvoiceDetail>(`/invoices/${invoiceId}/assessment`, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}


export async function autofillGeolocation(invoiceId: number): Promise<InvoiceDetail> {
  return request<InvoiceDetail>(`/invoices/${invoiceId}/geolocation/autofill`, {
    method: "POST",
    body: JSON.stringify({}),
  });
}


export async function uploadFile(
  file: File,
  options?: { invoiceId?: number | null; section?: string | null },
): Promise<UploadResponse> {
  const formData = new FormData();
  formData.append("file", file);
  if (options?.invoiceId) {
    formData.append("invoice_id", String(options.invoiceId));
  }
  if (options?.section) {
    formData.append("section", options.section);
  }
  return request<UploadResponse>("/uploads", {
    method: "POST",
    body: formData,
  });
}


export function absoluteFileUrl(path: string): string {
  return path.startsWith("http") ? path : `${API_ORIGIN}${path}`;
}
