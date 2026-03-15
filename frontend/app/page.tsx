"use client";

import { useDeferredValue, useEffect, useState, useTransition } from "react";

import {
  ApiError,
  autofillGeolocation,
  createInvoice,
  getInvoice,
  getInvoiceAuditLogs,
  getInvoices,
  getMetrics,
  getMe,
  getReferenceOptions,
  getStoredToken,
  login,
  logout,
  reverseGeocode,
  storeTokens,
  syncWarehub,
  updateAssessment,
  updateInvoice,
  uploadFile,
  type GeolocationAutofillPayload,
  type InvoiceCreatePayload,
  type InvoiceMetadataPayload,
} from "../lib/api";
import {
  DEFAULT_LOCALE,
  LOCALE_LABELS,
  SUPPORTED_LOCALES,
  detectPreferredLocale,
  formatCurrency,
  formatDate,
  formatDateTime,
  formatPercent,
  formatTime,
  getMessages,
  storeLocale,
  translateAuditAction,
  translateAuditSummary,
  translateBlocker,
  translateBreakdownLabel,
  translateComplianceChoice,
  translateDocumentStatus,
  translateEvidenceSection,
  translateInvoiceStatus,
  translateMaterialType,
  translateRiskLevel,
  translateRole,
  translateStorageBackend,
  translateWoodSpecies,
  type Locale,
} from "../lib/i18n";
import type {
  AssessmentPayload,
  AuditLogEntry,
  DashboardMetrics,
  Evidence,
  InvoiceDetail,
  InvoiceSummary,
  ReferenceOptions,
  UserPublic,
} from "../lib/types";
import { EvidenceEditor } from "./evidence-editor";
import { MapPicker } from "./map-picker";
import { RiskRing } from "./risk-ring";


const EVIDENCE_SECTIONS = [
  "certificate",
  "notice",
  "transport_papers",
  "geolocation_screenshot",
  "others",
] as const;

const STATUS_OPTIONS = ["pending", "partial", "paid", "cancelled", "draft", "unknown"];

type EvidenceKey = (typeof EVIDENCE_SECTIONS)[number];
type ThemeMode = "light" | "dark";
type WorkspaceTab = "overview" | "evidence" | "analytics";
type FieldTone = "positive" | "negative" | "warning" | "neutral";

type FactorySummaryView = {
  name: string;
  country: string | null;
  invoiceCount: number;
  highRiskCount: number;
  remainingAmount: number;
};

type ExtraCopy = {
  factoryFilter: string;
  allFactories: string;
  factories: string;
  factoryHint: string;
  mapPicker: string;
  mapPickerHint: string;
  dangerLabel: string;
};

const THEME_STORAGE_KEY = "woodguard_theme";
const ALL_FACTORIES_VALUE = "__all_factories__";
const EXTRA_COPY: Record<Locale, ExtraCopy> = {
  en: {
    factoryFilter: "Factory Filter",
    allFactories: "All factories",
    factories: "Factories",
    factoryHint: "Derived from seller/company fields until a dedicated factories endpoint is available.",
    mapPicker: "Map Geolocation Picker",
    mapPickerHint: "Click on the map to place the geolocation pin.",
    dangerLabel: "DANGER",
  },
  ru: {
    factoryFilter: "\u0424\u0438\u043b\u044c\u0442\u0440 \u0444\u0430\u0431\u0440\u0438\u043a",
    allFactories: "\u0412\u0441\u0435 \u0444\u0430\u0431\u0440\u0438\u043a\u0438",
    factories: "\u0424\u0430\u0431\u0440\u0438\u043a\u0438",
    factoryHint:
      "\u041f\u043e\u043a\u0430 \u0447\u0442\u043e \u0441\u043f\u0438\u0441\u043e\u043a \u0441\u043e\u0431\u0440\u0430\u043d \u0438\u0437 seller/company, \u043f\u043e\u043a\u0430 \u043d\u0435\u0442 \u043e\u0442\u0434\u0435\u043b\u044c\u043d\u043e\u0433\u043e endpoint \u0444\u0430\u0431\u0440\u0438\u043a.",
    mapPicker: "\u0412\u044b\u0431\u043e\u0440 \u0433\u0435\u043e\u043b\u043e\u043a\u0430\u0446\u0438\u0438 \u043d\u0430 \u043a\u0430\u0440\u0442\u0435",
    mapPickerHint: "\u041a\u043b\u0438\u043a\u043d\u0438\u0442\u0435 \u043f\u043e \u043a\u0430\u0440\u0442\u0435, \u0447\u0442\u043e\u0431\u044b \u043f\u043e\u0441\u0442\u0430\u0432\u0438\u0442\u044c \u0442\u043e\u0447\u043a\u0443.",
    dangerLabel: "DANGER",
  },
  de: {
    factoryFilter: "Werksfilter",
    allFactories: "Alle Werke",
    factories: "Werke",
    factoryHint: "Aus Seller-/Company-Feldern abgeleitet, bis ein eigener Factory-Endpunkt vorhanden ist.",
    mapPicker: "Kartenauswahl der Geolokation",
    mapPickerHint: "Klicke auf die Karte, um den Punkt zu setzen.",
    dangerLabel: "DANGER",
  },
};


function parseNumber(value: string): number | null {
  if (!value.trim()) {
    return null;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}


function normalizeText(value: string | null | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}


function getInitials(value: string): string {
  const parts = value
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2);

  if (!parts.length) {
    return "WG";
  }

  return parts.map((part) => part[0]?.toUpperCase() ?? "").join("");
}


function formatCoordinate(value: number | null): string {
  return value === null ? "--" : value.toFixed(6);
}


function buildOpenStreetMapEmbedUrl(latitude: number, longitude: number): string {
  const delta = 0.03;
  const left = longitude - delta;
  const right = longitude + delta;
  const top = latitude + delta;
  const bottom = latitude - delta;
  return `https://www.openstreetmap.org/export/embed.html?bbox=${left}%2C${bottom}%2C${right}%2C${top}&layer=mapnik&marker=${latitude}%2C${longitude}`;
}


function buildOpenStreetMapUrl(latitude: number, longitude: number): string {
  return `https://www.openstreetmap.org/?mlat=${latitude}&mlon=${longitude}#map=12/${latitude}/${longitude}`;
}


function getFactoryName(invoice: Pick<InvoiceSummary, "seller_name" | "company_name">, fallback: string): string {
  return normalizeText(invoice.seller_name) ?? normalizeText(invoice.company_name) ?? fallback;
}


function buildFactorySummaries(items: InvoiceSummary[], fallback: string): FactorySummaryView[] {
  const factories = new Map<string, FactorySummaryView>();

  for (const invoice of items) {
    const factoryName = getFactoryName(invoice, fallback);
    const current = factories.get(factoryName) ?? {
      name: factoryName,
      country: invoice.company_country_name ?? invoice.company_country ?? null,
      invoiceCount: 0,
      highRiskCount: 0,
      remainingAmount: 0,
    };

    current.invoiceCount += 1;
    current.remainingAmount += invoice.remaining_amount;
    if (!current.country) {
      current.country = invoice.company_country_name ?? invoice.company_country ?? null;
    }
    if (invoice.risk.risk_level === "high") {
      current.highRiskCount += 1;
    }

    factories.set(factoryName, current);
  }

  return Array.from(factories.values()).sort((left, right) => {
    if (right.highRiskCount !== left.highRiskCount) {
      return right.highRiskCount - left.highRiskCount;
    }
    if (right.invoiceCount !== left.invoiceCount) {
      return right.invoiceCount - left.invoiceCount;
    }
    return left.name.localeCompare(right.name);
  });
}


function getComplianceTone(value: AssessmentPayload["child_labor_ok"]): FieldTone {
  switch (value) {
    case "yes":
      return "positive";
    case "no":
      return "negative";
    default:
      return "warning";
  }
}


function getRiskTone(value: AssessmentPayload["personal_risk_level"]): FieldTone {
  switch (value) {
    case "low":
      return "positive";
    case "high":
      return "negative";
    case "medium":
      return "warning";
    default:
      return "neutral";
  }
}


function buildMapSelectionLabel(latitude: number, longitude: number): string {
  return `Map pin ${latitude.toFixed(5)}, ${longitude.toFixed(5)}`;
}


function buildCurrentLocationLabel(latitude: number, longitude: number): string {
  return `Current location ${latitude.toFixed(5)}, ${longitude.toFixed(5)}`;
}


function shouldReplaceDerivedLocationText(value: string | null | undefined): boolean {
  const normalized = value?.trim() ?? "";
  return !normalized || normalized.startsWith("Map pin ") || normalized.startsWith("Current location ");
}


function getMeaningfulCompanyName(detail: InvoiceDetail | null): string | null {
  const companyName = normalizeText(detail?.company_name);
  if (!companyName) {
    return null;
  }
  return companyName.trim().toLowerCase() === "unassigned supplier" ? null : companyName;
}


function hasGeolocationAutofillInput(detail: InvoiceDetail | null): boolean {
  if (!detail) {
    return false;
  }

  return Boolean(
    normalizeText(detail.assessment.geolocation_source_text) ??
    normalizeText(detail.seller_geolocation_label) ??
    normalizeText(detail.seller_address) ??
    normalizeText(detail.seller_name) ??
    getMeaningfulCompanyName(detail),
  );
}


export default function Page() {
  const [locale, setLocale] = useState<Locale>(DEFAULT_LOCALE);
  const [theme, setTheme] = useState<ThemeMode>("light");
  const [activeTab, setActiveTab] = useState<WorkspaceTab>("overview");
  const [authChecked, setAuthChecked] = useState(false);
  const [currentUser, setCurrentUser] = useState<UserPublic | null>(null);
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);
  const [reference, setReference] = useState<ReferenceOptions | null>(null);
  const [invoices, setInvoices] = useState<InvoiceSummary[]>([]);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [draft, setDraft] = useState<InvoiceDetail | null>(null);
  const [auditLogs, setAuditLogs] = useState<AuditLogEntry[]>([]);
  const [search, setSearch] = useState("");
  const [factoryFilter, setFactoryFilter] = useState(ALL_FACTORIES_VALUE);
  const deferredSearch = useDeferredValue(search);
  const [statusMessage, setStatusMessage] = useState<{ type: "error" | "info"; text: string } | null>(null);
  const [isAutofillingGeolocation, setIsAutofillingGeolocation] = useState(false);
  const [isUsingCurrentLocation, setIsUsingCurrentLocation] = useState(false);
  const [manualForm, setManualForm] = useState({
    invoice_number: "",
    company_name: "",
    company_country: "TR",
    amount: "0",
  });
  const [loginForm, setLoginForm] = useState({
    username: "admin",
    password: "woodguard123",
  });
  const [isPending, startTransition] = useTransition();
  const t = getMessages(locale);
  const extraCopy = EXTRA_COPY[locale];

  useEffect(() => {
    setLocale(detectPreferredLocale());
  }, []);

  useEffect(() => {
    storeLocale(locale);
    document.documentElement.lang = locale;
  }, [locale]);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }
    const storedTheme = window.localStorage.getItem(THEME_STORAGE_KEY);
    if (storedTheme === "light" || storedTheme === "dark") {
      setTheme(storedTheme);
      return;
    }
    setTheme(window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }
    window.localStorage.setItem(THEME_STORAGE_KEY, theme);
    document.documentElement.dataset.theme = theme;
  }, [theme]);

  function resetWorkspace() {
    setMetrics(null);
    setReference(null);
    setInvoices([]);
    setSelectedId(null);
    setDraft(null);
    setAuditLogs([]);
  }

  function handleUnauthorized() {
    storeTokens(null, null);
    setCurrentUser(null);
    resetWorkspace();
    setAuthChecked(true);
  }

  async function loadInvoiceContext(invoiceId: number) {
    const [detail, audit] = await Promise.all([
      getInvoice(invoiceId),
      getInvoiceAuditLogs(invoiceId),
    ]);
    setSelectedId(invoiceId);
    setDraft(detail);
    setAuditLogs(audit.items);
  }

  async function loadDashboard(preferredInvoiceId?: number | null) {
    try {
      const [metricsData, invoiceData, referenceData] = await Promise.all([
        getMetrics(),
        getInvoices(),
        getReferenceOptions(),
      ]);
      setMetrics(metricsData);
      setInvoices(invoiceData.items);
      setReference(referenceData);

      const targetId = preferredInvoiceId ?? selectedId ?? invoiceData.items[0]?.id ?? null;
      if (targetId) {
        await loadInvoiceContext(targetId);
      } else {
        setSelectedId(null);
        setDraft(null);
        setAuditLogs([]);
      }
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        handleUnauthorized();
        return;
      }
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.loadDashboardFailed,
      });
    }
  }

  useEffect(() => {
    const storedToken = getStoredToken();
    if (!storedToken) {
      setAuthChecked(true);
      return;
    }

    startTransition(() => {
      void getMe()
        .then(async (user) => {
          setCurrentUser(user);
          await loadDashboard();
        })
        .catch(() => {
          handleUnauthorized();
        })
        .finally(() => setAuthChecked(true));
    });
  }, []);

  const factorySummaries = buildFactorySummaries(invoices, t.unassignedSupplier);

  useEffect(() => {
    if (factoryFilter === ALL_FACTORIES_VALUE) {
      return;
    }

    if (!factorySummaries.some((factory) => factory.name === factoryFilter)) {
      setFactoryFilter(ALL_FACTORIES_VALUE);
    }
  }, [factoryFilter, factorySummaries]);

  const filteredInvoices = invoices.filter((invoice) => {
    if (factoryFilter !== ALL_FACTORIES_VALUE && getFactoryName(invoice, t.unassignedSupplier) !== factoryFilter) {
      return false;
    }

    if (!deferredSearch.trim()) {
      return true;
    }

    const haystack = `${invoice.invoice_number} ${invoice.company_name ?? ""} ${invoice.seller_name ?? ""}`.toLowerCase();
    return haystack.includes(deferredSearch.toLowerCase());
  });
  const filteredInvoiceIdsKey = filteredInvoices.map((invoice) => invoice.id).join(",");

  useEffect(() => {
    if (!currentUser) {
      return;
    }

    if (!filteredInvoices.length) {
      setSelectedId(null);
      setDraft(null);
      setAuditLogs([]);
      return;
    }

    if (selectedId && filteredInvoices.some((invoice) => invoice.id === selectedId)) {
      return;
    }

    void handleSelect(filteredInvoices[0].id);
  }, [currentUser, filteredInvoiceIdsKey, selectedId]);

  const setDraftValue = <K extends keyof InvoiceDetail>(field: K, value: InvoiceDetail[K]) => {
    setDraft((current) => (current ? { ...current, [field]: value } : current));
  };

  const setAssessmentValue = <K extends keyof AssessmentPayload>(field: K, value: AssessmentPayload[K]) => {
    setDraft((current) => (current ? { ...current, assessment: { ...current.assessment, [field]: value } } : current));
  };

  const setEvidenceValue = <K extends keyof Evidence>(section: EvidenceKey, field: K, value: Evidence[K]) => {
    setDraft((current) =>
      current
        ? {
            ...current,
            assessment: {
              ...current.assessment,
              [section]: { ...current.assessment[section], [field]: value },
            },
          }
        : current,
    );
  };

  function handleMapLocationPick(latitude: number, longitude: number) {
    setDraft((current) => {
      if (!current) {
        return current;
      }

      const currentSource = current.assessment.geolocation_source_text?.trim() ?? "";
      const nextSource = !currentSource || currentSource.startsWith("Map pin ")
        ? buildMapSelectionLabel(latitude, longitude)
        : current.assessment.geolocation_source_text;

      return {
        ...current,
        assessment: {
          ...current.assessment,
          geolocation_latitude: latitude,
          geolocation_longitude: longitude,
          geolocation_source_text: nextSource,
        },
      };
    });
  }

  const toggleArraySelection = (field: "wood_species" | "material_types", value: string) => {
    setDraft((current) => {
      if (!current) {
        return current;
      }
      const values = current.assessment[field];
      const nextValues = values.includes(value)
        ? values.filter((item) => item !== value)
        : [...values, value];
      return {
        ...current,
        assessment: { ...current.assessment, [field]: nextValues },
      };
    });
  };

  async function handleSelect(invoiceId: number) {
    try {
      await loadInvoiceContext(invoiceId);
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        handleUnauthorized();
        return;
      }
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.loadInvoiceFailed,
      });
    }
  }

  async function handleSync() {
    try {
      setStatusMessage({ type: "info", text: t.syncingWarehubStatus });
      await syncWarehub();
      await loadDashboard(selectedId);
      setStatusMessage({ type: "info", text: t.warehubSyncCompleted });
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        handleUnauthorized();
        return;
      }
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.warehubSyncFailed,
      });
    }
  }

  async function handleCreateManual() {
    if (!manualForm.invoice_number.trim()) {
      setStatusMessage({ type: "error", text: t.manualInvoiceNumberRequired });
      return;
    }

    const payload: InvoiceCreatePayload = {
      invoice_number: manualForm.invoice_number.trim(),
      company_name: normalizeText(manualForm.company_name),
      company_country: normalizeText(manualForm.company_country),
      amount: parseNumber(manualForm.amount) ?? 0,
      status: "pending",
    };

    try {
      const created = await createInvoice(payload);
      setManualForm((current) => ({ ...current, invoice_number: "", company_name: "", amount: "0" }));
      await loadDashboard(created.id);
      setStatusMessage({ type: "info", text: t.manualInvoiceCreated });
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        handleUnauthorized();
        return;
      }
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.createInvoiceFailed,
      });
    }
  }

  async function handleUpload(section: EvidenceKey, files: FileList | null) {
    if (!files?.length || !draft) {
      return;
    }

    try {
      const uploaded = await Promise.all(
        Array.from(files).map((file) => uploadFile(file, { invoiceId: draft.id, section })),
      );

      setDraft((current) =>
        current
          ? {
              ...current,
              assessment: {
                ...current.assessment,
                [section]: {
                  ...current.assessment[section],
                  status: "uploaded",
                  files: [...current.assessment[section].files, ...uploaded.map((item) => item.url)],
                },
              },
            }
          : current,
      );

      const audit = await getInvoiceAuditLogs(draft.id);
      setAuditLogs(audit.items);
      setStatusMessage({
        type: "info",
        text: t.uploadedFiles(uploaded.length, translateStorageBackend(locale, uploaded[0]?.storage_backend ?? "local")),
      });
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        handleUnauthorized();
        return;
      }
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.fileUploadFailed,
      });
    }
  }

  async function handleSave() {
    if (!draft) {
      return;
    }

    const metadata: InvoiceMetadataPayload = {
      company_name: normalizeText(draft.company_name),
      company_country: normalizeText(draft.company_country),
      invoice_date: draft.invoice_date,
      production_date: draft.production_date,
      import_date: draft.import_date,
      due_date: draft.due_date,
      amount: draft.amount,
      total_paid: draft.total_paid,
      remaining_amount: draft.remaining_amount,
      status: draft.status,
      notes: normalizeText(draft.notes),
      seller_name: normalizeText(draft.seller_name),
      seller_address: normalizeText(draft.seller_address),
      seller_phone: normalizeText(draft.seller_phone),
      seller_email: normalizeText(draft.seller_email),
      seller_website: normalizeText(draft.seller_website),
      seller_contact_person: normalizeText(draft.seller_contact_person),
      seller_geolocation_label: normalizeText(draft.seller_geolocation_label),
      seller_latitude: draft.seller_latitude,
      seller_longitude: draft.seller_longitude,
    };

    try {
      setStatusMessage({ type: "info", text: t.saveDossierStatus });
      await updateInvoice(draft.id, metadata);
      const updated = await updateAssessment(draft.id, draft.assessment);
      setDraft(updated);
      await loadDashboard(updated.id);
      setStatusMessage({ type: "info", text: t.dossierSaved });
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        handleUnauthorized();
        return;
      }
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.saveInvoiceFailed,
      });
    }
  }

  async function handleAutofillGeolocation() {
    if (!draft) {
      return;
    }

    if (!hasGeolocationAutofillInput(draft)) {
      setStatusMessage({
        type: "error",
        text: [t.geolocationLabel, t.address, t.sellerName, t.companyName].join(" / "),
      });
      return;
    }

    try {
      const payload: GeolocationAutofillPayload = {};
      const companyName = getMeaningfulCompanyName(draft);
      const companyCountry = normalizeText(draft.company_country);
      const sellerName = normalizeText(draft.seller_name);
      const sellerAddress = normalizeText(draft.seller_address);
      const sellerGeolocationLabel = normalizeText(draft.seller_geolocation_label);
      const geolocationSourceText = normalizeText(draft.assessment.geolocation_source_text);

      if (companyName) payload.company_name = companyName;
      if (companyCountry) payload.company_country = companyCountry;
      if (sellerName) payload.seller_name = sellerName;
      if (sellerAddress) payload.seller_address = sellerAddress;
      if (sellerGeolocationLabel) payload.seller_geolocation_label = sellerGeolocationLabel;
      if (geolocationSourceText) payload.geolocation_source_text = geolocationSourceText;

      setIsAutofillingGeolocation(true);
      setStatusMessage({ type: "info", text: t.autoDetectLocation });
      const updated = await autofillGeolocation(draft.id, payload);
      setDraft(updated);
      const audit = await getInvoiceAuditLogs(draft.id);
      setAuditLogs(audit.items);
      const latitude = updated.assessment.geolocation_latitude ?? updated.seller_latitude;
      const longitude = updated.assessment.geolocation_longitude ?? updated.seller_longitude;
      setStatusMessage({
        type: "info",
        text: latitude !== null && longitude !== null
          ? `${t.autoDetectLocation}: ${formatCoordinate(latitude)}, ${formatCoordinate(longitude)}`
          : t.dossierSaved,
      });
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        handleUnauthorized();
        return;
      }
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.loadInvoiceFailed,
      });
    } finally {
      setIsAutofillingGeolocation(false);
    }
  }

  async function handleUseCurrentLocation() {
    if (!draft) {
      return;
    }

    if (typeof window === "undefined" || !("geolocation" in window.navigator)) {
      setStatusMessage({ type: "error", text: t.currentLocationUnavailable });
      return;
    }

    try {
      setIsUsingCurrentLocation(true);
      setStatusMessage({ type: "info", text: t.currentLocationStatus });

      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        window.navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 12000,
          maximumAge: 0,
        });
      });

      const latitude = Number(position.coords.latitude.toFixed(6));
      const longitude = Number(position.coords.longitude.toFixed(6));
      let derivedLabel = buildCurrentLocationLabel(latitude, longitude);
      let resolvedAddress: string | null = null;
      let reverseLookupFailed = false;

      try {
        const resolved = await reverseGeocode(latitude, longitude);
        derivedLabel = resolved.display_name;
        resolvedAddress = resolved.display_name;
      } catch (error) {
        if (error instanceof ApiError && error.status === 401) {
          handleUnauthorized();
          return;
        }
        reverseLookupFailed = true;
      }

      setDraft((current) => {
        if (!current) {
          return current;
        }

        const nextSellerAddress = normalizeText(current.seller_address) ?? resolvedAddress ?? current.seller_address;
        const nextGeolocationLabel = shouldReplaceDerivedLocationText(current.seller_geolocation_label)
          ? derivedLabel
          : current.seller_geolocation_label;
        const nextSource = shouldReplaceDerivedLocationText(current.assessment.geolocation_source_text)
          ? derivedLabel
          : current.assessment.geolocation_source_text;

        return {
          ...current,
          seller_address: nextSellerAddress,
          seller_geolocation_label: nextGeolocationLabel,
          seller_latitude: latitude,
          seller_longitude: longitude,
          assessment: {
            ...current.assessment,
            geolocation_latitude: latitude,
            geolocation_longitude: longitude,
            geolocation_source_text: nextSource,
          },
        };
      });

      setStatusMessage({
        type: "info",
        text: reverseLookupFailed ? t.currentLocationCoordinatesOnly : t.currentLocationSavedDraft,
      });
    } catch (error) {
      const errorCode =
        typeof error === "object" && error !== null && "code" in error ? Number((error as { code?: unknown }).code) : null;

      setStatusMessage({
        type: "error",
        text:
          errorCode === 1
            ? t.currentLocationPermissionDenied
            : error instanceof Error && error.message
              ? error.message
              : t.currentLocationUnavailable,
      });
    } finally {
      setIsUsingCurrentLocation(false);
    }
  }

  async function handleLogin() {
    try {
      setStatusMessage({ type: "info", text: t.signingIn });
      const response = await login(loginForm.username, loginForm.password);
      setCurrentUser(response.user);
      await loadDashboard();
      setAuthChecked(true);
      setStatusMessage({ type: "info", text: t.signedInAs(response.user.username) });
    } catch (error) {
      storeTokens(null, null);
      setStatusMessage({
        type: "error",
        text: error instanceof Error ? error.message : t.loginFailed,
      });
      setAuthChecked(true);
    }
  }

  async function handleLogout() {
    try {
      await logout();
    } catch {
      storeTokens(null, null);
    }
    setCurrentUser(null);
    resetWorkspace();
    setStatusMessage({ type: "info", text: t.signedOut });
  }

  const evidenceRecords = draft ? EVIDENCE_SECTIONS.map((section) => draft.assessment[section]) : [];
  const pendingEvidenceCount = evidenceRecords.filter((item) => item.status === "missing" && item.files.length === 0).length;
  const uploadedEvidenceCount = evidenceRecords.reduce((total, item) => total + item.files.length, 0);
  const verifiedSectionsCount = evidenceRecords.filter((item) => item.status === "verified").length;
  const recentInvoices = filteredInvoices.slice(0, 6);
  const latestAuditEntry = auditLogs[0] ?? null;
  const latestAuditDate = latestAuditEntry ? formatDate(locale, latestAuditEntry.created_at) : t.unset;
  const latestAuditTime = latestAuditEntry ? formatTime(locale, latestAuditEntry.created_at) : null;
  const filteredOpenExposure = filteredInvoices.reduce((total, invoice) => total + invoice.remaining_amount, 0);
  const filteredCoverageAverage = filteredInvoices.length
    ? filteredInvoices.reduce((total, invoice) => total + invoice.risk.coverage_percent, 0) / filteredInvoices.length
    : 0;
  const filteredHighRiskCount = filteredInvoices.filter((invoice) => invoice.risk.risk_level === "high").length;
  const analyticsAlerts = draft
    ? [
        draft.assessment.child_labor_ok === "no"
          ? {
              title: t.childLabor,
              text: translateBlocker(locale, "Child labor concern flagged."),
            }
          : null,
        draft.assessment.human_rights_ok === "no"
          ? {
              title: t.humanRights,
              text: translateBlocker(locale, "Human rights concern flagged."),
            }
          : null,
        draft.assessment.personal_risk_level === "high"
          ? {
              title: t.personalRiskAssessment,
              text: draft.assessment.risk_reason ?? translateBlocker(locale, "Reviewer marked this invoice as high risk."),
            }
          : null,
      ].filter((item): item is { title: string; text: string } => Boolean(item))
    : [];
  const notificationItems = draft
    ? [
        {
          tone: draft.risk.risk_level,
          title: t.riskScore,
          text: `${translateRiskLevel(locale, draft.risk.risk_level)} | ${Math.round(draft.risk.risk_score)}%`,
        },
        {
          tone: pendingEvidenceCount > 0 ? "medium" : "low",
          title: t.pendingEvidence,
          text: pendingEvidenceCount > 0 ? String(pendingEvidenceCount) : formatPercent(locale, draft.risk.coverage_percent),
        },
        {
          tone: "low" as const,
          title: t.latestActivity,
          text: latestAuditEntry ? formatDateTime(locale, latestAuditEntry.created_at) : t.noAuditActivity,
        },
      ]
    : [];
  const canAutofillLocation = hasGeolocationAutofillInput(draft);
  const isLocationActionPending = isAutofillingGeolocation || isUsingCurrentLocation;
  const autofillLocationHint = [t.geolocationLabel, t.address, t.sellerName, t.companyName].join(" / ");

  const languageSwitcher = (
    <div className="localeSwitch" aria-label={t.language}>
      {SUPPORTED_LOCALES.map((item) => (
        <button
          key={item}
          type="button"
          className={`localeButton ${locale === item ? "active" : ""}`}
          onClick={() => setLocale(item)}
          title={LOCALE_LABELS[item]}
        >
          {item.toUpperCase()}
        </button>
      ))}
    </div>
  );

  const themeSwitcher = (
    <div className="themeSwitch" aria-label={t.theme}>
      <button type="button" className={`themeButton ${theme === "light" ? "active" : ""}`} onClick={() => setTheme("light")}>
        {t.light}
      </button>
      <button type="button" className={`themeButton ${theme === "dark" ? "active" : ""}`} onClick={() => setTheme("dark")}>
        {t.dark}
      </button>
    </div>
  );

  function renderEmptyWorkspace(tabLabel: string) {
    return (
      <section className="panel emptyPanel">
        <p className="eyebrow">{tabLabel}</p>
        <h2>{t.noInvoicesYet}</h2>
        <button className="button" onClick={() => void handleSync()} disabled={!currentUser || currentUser.role === "viewer"}>
          {t.syncWarehub}
        </button>
      </section>
    );
  }

  function renderOverviewTab() {
    if (!draft) {
      return renderEmptyWorkspace(t.overviewTab);
    }

    const geoLatitude = draft.assessment.geolocation_latitude ?? draft.seller_latitude;
    const geoLongitude = draft.assessment.geolocation_longitude ?? draft.seller_longitude;
    const geoSource =
      draft.assessment.geolocation_source_text ??
      draft.seller_geolocation_label ??
      draft.seller_address ??
      draft.seller_name ??
      t.unset;
    const hasGeo = geoLatitude !== null && geoLongitude !== null;

    return (
      <>
        <section className="panel workspaceHero">
          <div className="workspaceHeroCopy">
            <p className="eyebrow">{draft.source === "warehub" ? t.orderHubInvoice : t.manualIndex}</p>
            <h2>{draft.company_name ?? t.unassignedSupplier}</h2>
            <p className="workspaceLead">{t.selectedInvoice}: {draft.invoice_number}</p>
            <div className="heroMeta">
              <span className="pill">{translateInvoiceStatus(locale, draft.status)}</span>
              <span className="pill">{t.amount}: {formatCurrency(locale, draft.amount)}</span>
              <span className="pill">{t.openShort}: {formatCurrency(locale, draft.remaining_amount)}</span>
              <span className={`pill ${draft.risk.risk_level}`}>{translateRiskLevel(locale, draft.risk.risk_level)}</span>
            </div>
          </div>
          <div className="workspaceHeroAside">
            <RiskRing risk={draft.risk} locale={locale} />
            <button className="button heroSaveButton" onClick={() => void handleSave()}>
              {t.saveInvoiceDossier}
            </button>
          </div>
        </section>

        <section className="metricGrid">
          <article className="panel metricCard"><span className="metricLabel">{t.riskScore}</span><strong>{Math.round(draft.risk.risk_score)}%</strong></article>
          <article className="panel metricCard"><span className="metricLabel">{t.coverage}</span><strong>{formatPercent(locale, draft.risk.coverage_percent)}</strong></article>
          <article className="panel metricCard"><span className="metricLabel">{t.openShort}</span><strong>{formatCurrency(locale, draft.remaining_amount)}</strong></article>
          <article className="panel metricCard"><span className="metricLabel">{t.pendingEvidence}</span><strong>{pendingEvidenceCount}</strong></article>
        </section>

        <section className="dashboardPanels">
          <article className="panel cardBody formCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.invoiceMetadata}</h2>
              <span className="panelBadge">{t.overviewTab}</span>
            </div>
            <div className="stack">
              <div className="gridTwo">
                <div className="formRow"><label>{t.companyName}</label><input className="textInput" value={draft.company_name ?? ""} onChange={(event) => setDraftValue("company_name", event.target.value)} /></div>
                <div className="formRow"><label>{t.country}</label><select className="selectInput" value={draft.company_country ?? ""} onChange={(event) => setDraftValue("company_country", event.target.value)}><option value="">{t.selectCountry}</option>{reference?.countries.map((country) => <option key={country.code} value={country.code}>{country.name} ({country.code})</option>)}</select></div>
              </div>
              <div className="gridTwo">
                <div className="formRow"><label>{t.invoiceNumber}</label><input className="textInput" value={draft.invoice_number} disabled /></div>
                <div className="formRow"><label>{t.status}</label><select className="selectInput" value={draft.status} onChange={(event) => setDraftValue("status", event.target.value)}>{STATUS_OPTIONS.map((status) => <option key={status} value={status}>{translateInvoiceStatus(locale, status)}</option>)}</select></div>
              </div>
              <div className="gridTwo">
                <div className="formRow"><label>{t.amount}</label><input className="textInput" type="number" value={draft.amount} onChange={(event) => setDraftValue("amount", Number(event.target.value))} /></div>
                <div className="formRow"><label>{t.remainingAmount}</label><input className="textInput" type="number" value={draft.remaining_amount} onChange={(event) => setDraftValue("remaining_amount", Number(event.target.value))} /></div>
              </div>
              <div className="gridTwo">
                <div className="formRow"><label>{t.invoiceDate}</label><input className="textInput" type="date" value={draft.invoice_date ?? ""} onChange={(event) => setDraftValue("invoice_date", event.target.value || null)} /></div>
                <div className="formRow"><label>{t.dueDate}</label><input className="textInput" type="date" value={draft.due_date ?? ""} onChange={(event) => setDraftValue("due_date", event.target.value || null)} /></div>
              </div>
              <div className="gridTwo">
                <div className="formRow"><label>{t.productionDate}</label><input className="textInput" type="date" value={draft.production_date ?? ""} onChange={(event) => setDraftValue("production_date", event.target.value || null)} /></div>
                <div className="formRow"><label>{t.importDate}</label><input className="textInput" type="date" value={draft.import_date ?? ""} onChange={(event) => setDraftValue("import_date", event.target.value || null)} /></div>
              </div>
              <div className="formRow"><label>{t.internalNotes}</label><textarea className="textArea" value={draft.notes ?? ""} onChange={(event) => setDraftValue("notes", event.target.value)} /></div>
            </div>
          </article>

          <article className="panel cardBody formCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.sellerCard}</h2>
              <span className="panelBadge">{t.selectedInvoice}</span>
            </div>
            <div className="stack">
              <div className="formRow"><label>{t.sellerName}</label><input className="textInput" value={draft.seller_name ?? ""} onChange={(event) => setDraftValue("seller_name", event.target.value)} /></div>
              <div className="formRow"><label>{t.address}</label><textarea className="textArea" value={draft.seller_address ?? ""} onChange={(event) => setDraftValue("seller_address", event.target.value)} /></div>
              <div className="gridTwo">
                <div className="formRow"><label>{t.phone}</label><input className="textInput" value={draft.seller_phone ?? ""} onChange={(event) => setDraftValue("seller_phone", event.target.value)} /></div>
                <div className="formRow"><label>{t.email}</label><input className="textInput" value={draft.seller_email ?? ""} onChange={(event) => setDraftValue("seller_email", event.target.value)} /></div>
              </div>
              <div className="gridTwo">
                <div className="formRow"><label>{t.website}</label><input className="textInput" value={draft.seller_website ?? ""} onChange={(event) => setDraftValue("seller_website", event.target.value)} /></div>
                <div className="formRow"><label>{t.contactPerson}</label><input className="textInput" value={draft.seller_contact_person ?? ""} onChange={(event) => setDraftValue("seller_contact_person", event.target.value)} /></div>
              </div>
              <div className="formRow"><label>{t.geolocationLabel}</label><input className="textInput" value={draft.seller_geolocation_label ?? ""} onChange={(event) => setDraftValue("seller_geolocation_label", event.target.value)} /></div>
              <div className="gridTwo">
                <div className="formRow"><label>{t.latitude}</label><input className="textInput" type="number" value={draft.seller_latitude ?? ""} onChange={(event) => setDraftValue("seller_latitude", parseNumber(event.target.value))} /></div>
                <div className="formRow"><label>{t.longitude}</label><input className="textInput" type="number" value={draft.seller_longitude ?? ""} onChange={(event) => setDraftValue("seller_longitude", parseNumber(event.target.value))} /></div>
              </div>
              <div className="gridTwo">
                <button
                  className="button secondary"
                  onClick={() => void handleUseCurrentLocation()}
                  disabled={isLocationActionPending}
                >
                  {t.useCurrentLocation}
                </button>
                <button
                  className="button secondary"
                  onClick={() => void handleAutofillGeolocation()}
                  disabled={isLocationActionPending || !canAutofillLocation}
                  title={!canAutofillLocation ? autofillLocationHint : undefined}
                >
                  {t.autoDetectLocation}
                </button>
              </div>
              <p className="helperText">{t.useCurrentLocationDescription}</p>
              {!canAutofillLocation ? <p className="helperText">{autofillLocationHint}</p> : null}
            </div>
          </article>
        </section>

        <section className="dashboardPanels bottomPanels overviewBottomPanels">
          <article className="panel cardBody geoCard geoCardExpanded">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.geoSnapshot}</h2>
              <span className="panelBadge">{t.mapPreview}</span>
            </div>
            <div className="geoMap">
              {hasGeo ? (
                <iframe
                  className="geoMapFrame"
                  src={buildOpenStreetMapEmbedUrl(geoLatitude, geoLongitude)}
                  loading="lazy"
                  referrerPolicy="no-referrer-when-downgrade"
                  title="Geolocation preview"
                />
              ) : (
                <>
                  <div className="geoMapGlow" />
                  <div className="geoMapGrid" />
                  <div className="geoMapPin" />
                </>
              )}
            </div>
            <div className="geoMeta">
              <span>{t.coordinates}</span>
              <strong>{formatCoordinate(geoLatitude)}, {formatCoordinate(geoLongitude)}</strong>
            </div>
            <div className="geoMeta">
              <span>{t.geolocationSource}</span>
              <strong>{geoSource}</strong>
            </div>
            {hasGeo ? (
              <a className="button secondary mapLinkButton" href={buildOpenStreetMapUrl(geoLatitude, geoLongitude)} target="_blank" rel="noreferrer">
                {t.openMap}
              </a>
            ) : null}
          </article>
        </section>
      </>
    );
  }

  function renderEvidenceTab() {
    if (!draft) {
      return renderEmptyWorkspace(t.evidenceTab);
    }

    return (
      <>
        <section className="metricGrid">
          <article className="panel metricCard"><span className="metricLabel">{t.pendingEvidence}</span><strong>{pendingEvidenceCount}</strong></article>
          <article className="panel metricCard"><span className="metricLabel">{t.uploadedEvidence}</span><strong>{uploadedEvidenceCount}</strong></article>
          <article className="panel metricCard"><span className="metricLabel">{t.verifiedSections}</span><strong>{verifiedSectionsCount}</strong></article>
          <article className="panel metricCard"><span className="metricLabel">{t.coverage}</span><strong>{formatPercent(locale, draft.risk.coverage_percent)}</strong></article>
        </section>

        <section className="panel cardBody">
          <div className="panelHead">
            <h2 className="sectionTitle">{t.evidenceSections}</h2>
            <span className="panelBadge">{t.evidenceTab}</span>
          </div>
          <div className="evidenceGrid wideEvidenceGrid">
            {EVIDENCE_SECTIONS.map((section) => (
              <EvidenceEditor
                key={section}
                title={translateEvidenceSection(locale, section)}
                evidence={draft.assessment[section]}
                locale={locale}
                onStatusChange={(value) => setEvidenceValue(section, "status", value)}
                onMemoChange={(value) => setEvidenceValue(section, "memo", value)}
                onUpload={(files) => void handleUpload(section, files)}
              />
            ))}
          </div>
        </section>

        <section className="dashboardPanels bottomPanels">
          <article className="panel cardBody formCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.woodSpecification}</h2>
              <span className="panelBadge">{t.selectedInvoice}</span>
            </div>
            <div className="stack">
              <div className="formRow">
                <label>{t.woodSpecies}</label>
                <div className="chipGrid">
                  {(reference?.wood_species ?? []).map((item) => (
                    <button
                      key={item}
                      type="button"
                      className={`chipButton ${draft.assessment.wood_species.includes(item) ? "active" : ""}`}
                      onClick={() => toggleArraySelection("wood_species", item)}
                    >
                      {translateWoodSpecies(locale, item)}
                    </button>
                  ))}
                </div>
              </div>
              <div className="formRow">
                <label>{t.materialTypes}</label>
                <div className="chipGrid">
                  {(reference?.material_types ?? []).map((item) => (
                    <button
                      key={item}
                      type="button"
                      className={`chipButton ${draft.assessment.material_types.includes(item) ? "active" : ""}`}
                      onClick={() => toggleArraySelection("material_types", item)}
                    >
                      {translateMaterialType(locale, item)}
                    </button>
                  ))}
                </div>
              </div>
              <div className="gridTwo">
                <div className="formRow">
                  <label>{t.countryOfOrigin}</label>
                  <select
                    className="selectInput"
                    value={draft.assessment.country_of_origin ?? ""}
                    onChange={(event) => setAssessmentValue("country_of_origin", event.target.value || null)}
                  >
                    <option value="">{t.selectCountry}</option>
                    {(reference?.countries ?? []).map((country) => (
                      <option key={country.code} value={country.code}>
                        {country.name} ({country.code})
                      </option>
                    ))}
                  </select>
                </div>
                <div className="formRow">
                  <label>{t.deliveryDate}</label>
                  <input
                    className="textInput"
                    type="date"
                    value={draft.assessment.delivery_date ?? ""}
                    onChange={(event) => setAssessmentValue("delivery_date", event.target.value || null)}
                  />
                </div>
              </div>
              <div className="gridTwo">
                <div className="formRow">
                  <label>{t.quantity}</label>
                  <input
                    className="textInput"
                    type="number"
                    value={draft.assessment.quantity ?? ""}
                    onChange={(event) => setAssessmentValue("quantity", parseNumber(event.target.value))}
                  />
                </div>
                <div className="formRow">
                  <label>{t.unit}</label>
                  <input
                    className="textInput"
                    value={draft.assessment.quantity_unit ?? ""}
                    onChange={(event) => setAssessmentValue("quantity_unit", event.target.value || null)}
                  />
                </div>
              </div>
              <div className="formRow">
                <label>{t.woodSpecificationMemo}</label>
                <textarea
                  className="textArea"
                  value={draft.assessment.wood_specification_memo ?? ""}
                  onChange={(event) => setAssessmentValue("wood_specification_memo", event.target.value || null)}
                />
              </div>
            </div>
          </article>

          <article className="panel cardBody insightCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.currentFiles}</h2>
              <span className="panelBadge">{uploadedEvidenceCount}</span>
            </div>
            <div className="compactList">
              {EVIDENCE_SECTIONS.map((section) => (
                <article className="compactAudit" key={section}>
                  <div>
                    <strong>{translateEvidenceSection(locale, section)}</strong>
                    <span>{draft.assessment[section].files.length} · {translateDocumentStatus(locale, draft.assessment[section].status)}</span>
                  </div>
                  <span className={`pill ${draft.assessment[section].status === "verified" ? "low" : draft.assessment[section].status === "uploaded" ? "medium" : "high"}`}>
                    {translateDocumentStatus(locale, draft.assessment[section].status)}
                  </span>
                </article>
              ))}
            </div>
          </article>
        </section>
      </>
    );
  }

  function renderAnalyticsTab() {
    if (!draft) {
      return renderEmptyWorkspace(t.analyticsTab);
    }

    return (
      <>
        <section className="metricGrid">
          <article className="panel metricCard">
            <span className="metricLabel">{t.coverage}</span>
            <strong>{formatPercent(locale, draft.risk.coverage_percent)}</strong>
          </article>
          <article className="panel metricCard">
            <span className="metricLabel">{t.penalties}</span>
            <strong>{draft.risk.penalty_points}</strong>
          </article>
          <article className="panel metricCard">
            <span className="metricLabel">{t.riskBlockers}</span>
            <strong>{draft.risk.blockers.length}</strong>
          </article>
          <article className="panel metricCard">
            <span className="metricLabel">{t.latestActivity}</span>
            <strong className="metricValueDate">
              <span>{latestAuditDate}</span>
              {latestAuditTime ? <small>{latestAuditTime}</small> : null}
            </strong>
          </article>
        </section>

        <section className="dashboardPanels">
          <article className="panel cardBody formCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.riskInputs}</h2>
              <span className="panelBadge">{t.analyticsTab}</span>
            </div>
            {analyticsAlerts.length ? (
              <div className="alertGrid">
                {analyticsAlerts.map((alert) => (
                  <article className="notificationItem high analyticsAlert" key={`${alert.title}-${alert.text}`}>
                    <span className="alertLabel">{extraCopy.dangerLabel}</span>
                    <strong>{alert.title}</strong>
                    <span>{alert.text}</span>
                  </article>
                ))}
              </div>
            ) : null}
            <div className="stack">
              <div className="gridTwo">
                <div className={`formRow toneField ${getComplianceTone(draft.assessment.child_labor_ok)}`}>
                  <label>{t.childLabor}</label>
                  <select
                    className="selectInput"
                    value={draft.assessment.child_labor_ok}
                    onChange={(event) => setAssessmentValue("child_labor_ok", event.target.value as AssessmentPayload["child_labor_ok"])}
                  >
                    {(reference?.compliance_choices ?? ["yes", "no", "unknown"]).map((item) => (
                      <option key={item} value={item}>
                        {translateComplianceChoice(locale, item)}
                      </option>
                    ))}
                  </select>
                </div>
                <div className={`formRow toneField ${getComplianceTone(draft.assessment.human_rights_ok)}`}>
                  <label>{t.humanRights}</label>
                  <select
                    className="selectInput"
                    value={draft.assessment.human_rights_ok}
                    onChange={(event) => setAssessmentValue("human_rights_ok", event.target.value as AssessmentPayload["human_rights_ok"])}
                  >
                    {(reference?.compliance_choices ?? ["yes", "no", "unknown"]).map((item) => (
                      <option key={item} value={item}>
                        {translateComplianceChoice(locale, item)}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="gridTwo">
                <div className={`formRow toneField ${getRiskTone(draft.assessment.personal_risk_level)}`}>
                  <label>{t.personalRiskAssessment}</label>
                  <select
                    className="selectInput"
                    value={draft.assessment.personal_risk_level ?? ""}
                    onChange={(event) =>
                      setAssessmentValue(
                        "personal_risk_level",
                        event.target.value ? (event.target.value as AssessmentPayload["personal_risk_level"]) : null,
                      )
                    }
                  >
                    <option value="">{t.unset}</option>
                    {(reference?.risk_levels ?? ["low", "medium", "high"]).map((item) => (
                      <option key={item} value={item}>
                        {translateRiskLevel(locale, item)}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="formRow toneField neutral">
                  <label>{t.geolocationSource}</label>
                  <input
                    className="textInput"
                    value={draft.assessment.geolocation_source_text ?? ""}
                    onChange={(event) => setAssessmentValue("geolocation_source_text", event.target.value || null)}
                  />
                </div>
              </div>
              <div className="formRow">
                <div className="panelHead compactPanelHead">
                  <label>{extraCopy.mapPicker}</label>
                  <span className="panelBadge hintBadge">{extraCopy.mapPickerHint}</span>
                </div>
                <MapPicker
                  latitude={draft.assessment.geolocation_latitude ?? draft.seller_latitude}
                  longitude={draft.assessment.geolocation_longitude ?? draft.seller_longitude}
                  onChange={handleMapLocationPick}
                />
              </div>
              <div className="gridTwo">
                <div className="formRow">
                  <label>{t.geoLatitude}</label>
                  <input
                    className="textInput"
                    type="number"
                    value={draft.assessment.geolocation_latitude ?? ""}
                    onChange={(event) => setAssessmentValue("geolocation_latitude", parseNumber(event.target.value))}
                  />
                </div>
                <div className="formRow">
                  <label>{t.geoLongitude}</label>
                  <input
                    className="textInput"
                    type="number"
                    value={draft.assessment.geolocation_longitude ?? ""}
                    onChange={(event) => setAssessmentValue("geolocation_longitude", parseNumber(event.target.value))}
                  />
                </div>
              </div>
              <div className="formRow">
                <label>{t.why}</label>
                <textarea
                  className="textArea"
                  value={draft.assessment.risk_reason ?? ""}
                  onChange={(event) => setAssessmentValue("risk_reason", event.target.value || null)}
                />
              </div>
              <button className="button" onClick={() => void handleSave()}>
                {t.saveDossier}
              </button>
            </div>
          </article>

          <article className="panel cardBody insightCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.riskBlockers}</h2>
              <span className="panelBadge">{draft.risk.blockers.length}</span>
            </div>
            <div className="compactList">
              {draft.risk.blockers.length ? (
                draft.risk.blockers.map((blocker) => (
                  <article className="notificationItem high dangerCaps" key={blocker}>
                    <strong>{translateBlocker(locale, blocker)}</strong>
                  </article>
                ))
              ) : (
                <p className="helperText">{t.noAuditActivity}</p>
              )}
            </div>

            <div className="panelHead secondary">
              <h3 className="sectionTitle">{t.riskScore}</h3>
              <span className={`pill ${draft.risk.risk_level}`}>{translateRiskLevel(locale, draft.risk.risk_level)}</span>
            </div>
            <div className="breakdownList">
              {draft.risk.breakdown.map((item) => (
                <div className="breakdownItem" key={item.key}>
                  <span>{translateBreakdownLabel(locale, item.key, item.label)}</span>
                  <strong>
                    {item.awarded_points} / {item.weight}
                  </strong>
                </div>
              ))}
            </div>
          </article>
        </section>

        <section className="panel cardBody">
          <div className="panelHead">
            <h2 className="sectionTitle">{t.auditTrail}</h2>
            <span className="panelBadge">{auditLogs.length}</span>
          </div>
          <div className="auditList">
            {auditLogs.length ? (
              auditLogs.map((entry) => {
                const actorRole =
                  entry.actor_role && ["admin", "analyst", "reviewer", "viewer"].includes(entry.actor_role)
                    ? translateRole(locale, entry.actor_role as UserPublic["role"])
                    : entry.actor_role;

                return (
                  <article className="auditItem" key={entry.id}>
                    <div className="panelHead secondary">
                      <div>
                        <strong>{translateAuditAction(locale, entry.action)}</strong>
                        <p className="helperText">
                          {translateAuditSummary(locale, entry.summary) ?? t.noSummaryProvided}
                        </p>
                      </div>
                      <span className="panelBadge">{formatDateTime(locale, entry.created_at)}</span>
                    </div>
                    <div className="invoiceMeta">
                      <span>
                        {t.actor}: {entry.actor_username ?? t.systemActor}
                      </span>
                      <span>{actorRole ?? t.systemActor}</span>
                      <span>{entry.entity_type}</span>
                    </div>
                  </article>
                );
              })
            ) : (
              <p className="helperText">{t.noAuditActivity}</p>
            )}
          </div>
        </section>
      </>
    );
  }

  function renderWorkspace() {
    switch (activeTab) {
      case "evidence":
        return renderEvidenceTab();
      case "analytics":
        return renderAnalyticsTab();
      default:
        return renderOverviewTab();
    }
  }

  if (!authChecked) {
    return (
      <main className="shell appStage">
        <section className="loginSurface loadingSurface">
          <div className="panel loadingPanel">
            <p className="eyebrow">{t.authEyebrow}</p>
            <h1>{t.checkingSession}</h1>
          </div>
        </section>
      </main>
    );
  }

  if (!currentUser) {
    return (
      <main className="shell appStage">
        <section className="loginSurface">
          <div className="loginShowcase panel">
            <div className="loginTools">
              {languageSwitcher}
              {themeSwitcher}
            </div>
            <p className="eyebrow">{t.indexEyebrow}</p>
            <h1>Woodguard</h1>
            <p className="showcaseLead">{t.indexTitle}</p>
            <p>{t.indexDescription}</p>
            <div className="loginShowcaseGrid">
              <article className="showcaseCard">
                <span>{t.invoices}</span>
                <strong>270+</strong>
              </article>
              <article className="showcaseCard">
                <span>{t.coverageAverage}</span>
                <strong>98%</strong>
              </article>
              <article className="showcaseCard">
                <span>{t.highRisk}</span>
                <strong>12</strong>
              </article>
            </div>
          </div>

          <div className="loginCard panel">
            <div className="loginAside">
              <div className="brandMark">WG</div>
              <div>
                <p className="eyebrow">{t.authEyebrow}</p>
                <h2>{t.authTitle}</h2>
                <p>{t.authDescription}</p>
              </div>
            </div>
            <div className="loginFormWrap">
              <div className="stack">
                <div className="formRow">
                  <label>{t.usernameOrEmail}</label>
                  <input
                    className="textInput"
                    value={loginForm.username}
                    onChange={(event) => setLoginForm((current) => ({ ...current, username: event.target.value }))}
                  />
                </div>
                <div className="formRow">
                  <label>{t.password}</label>
                  <input
                    className="textInput"
                    type="password"
                    value={loginForm.password}
                    onChange={(event) => setLoginForm((current) => ({ ...current, password: event.target.value }))}
                  />
                </div>
                <button className="button loginButton" onClick={() => void handleLogin()} disabled={isPending}>
                  {t.signIn}
                </button>
                <p className="helperText">{t.defaultAdminNote}</p>
                {statusMessage ? <div key={`${statusMessage.type}-${statusMessage.text}`} className={`statusBar ${statusMessage.type}`}>{statusMessage.text}</div> : null}
              </div>
            </div>
          </div>
        </section>
      </main>
    );
  }

  const canSync = currentUser.role !== "viewer";
  const userDisplayName = currentUser.full_name ?? currentUser.username;
  const userInitials = getInitials(userDisplayName);
  const visibleFactories = factorySummaries.slice(0, 6);
  const dashboardStats = [
    { label: t.invoices, value: filteredInvoices.length.toString() },
    { label: t.openExposure, value: formatCurrency(locale, filteredOpenExposure) },
    { label: t.coverageAverage, value: formatPercent(locale, filteredCoverageAverage) },
    { label: t.highRisk, value: filteredHighRiskCount.toString() },
  ];

  return (
    <main className="shell appStage">
      <section className="appSurface">
        <aside className="chromeSidebar">
          <div className="sidebarBrand">
            <div className="brandMark">WG</div>
            <div>
              <strong>Woodguard</strong>
              <span>{t.indexEyebrow}</span>
            </div>
          </div>

          <nav className="navMenu">
            {[
              { key: "overview" as const, label: t.overviewTab },
              { key: "evidence" as const, label: t.evidenceTab },
              { key: "analytics" as const, label: t.analyticsTab },
            ].map((item) => (
              <button
                key={item.key}
                type="button"
                className={`navButton ${activeTab === item.key ? "active" : ""}`}
                onClick={() => startTransition(() => setActiveTab(item.key))}
              >
                <span className="navIcon" />
                <span>{item.label}</span>
              </button>
            ))}
          </nav>

          <section className="sidebarCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.createNewIndex}</h2>
              <span className="panelBadge">+</span>
            </div>
            <div className="stack">
              <div className="formRow">
                <label>{t.invoiceNumber}</label>
                <input
                  className="textInput"
                  value={manualForm.invoice_number}
                  onChange={(event) => setManualForm((current) => ({ ...current, invoice_number: event.target.value }))}
                />
              </div>
              <div className="formRow">
                <label>{t.companyName}</label>
                <input
                  className="textInput"
                  value={manualForm.company_name}
                  onChange={(event) => setManualForm((current) => ({ ...current, company_name: event.target.value }))}
                />
              </div>
              <div className="gridTwo">
                <div className="formRow">
                  <label>{t.country}</label>
                  <select
                    className="selectInput"
                    value={manualForm.company_country}
                    onChange={(event) => setManualForm((current) => ({ ...current, company_country: event.target.value }))}
                  >
                    {reference?.countries.length ? (
                      reference.countries.map((country) => (
                        <option key={country.code} value={country.code}>
                          {country.name} ({country.code})
                        </option>
                      ))
                    ) : (
                      <option value="TR">TR</option>
                    )}
                  </select>
                </div>
                <div className="formRow">
                  <label>{t.amount}</label>
                  <input
                    className="textInput"
                    type="number"
                    value={manualForm.amount}
                    onChange={(event) => setManualForm((current) => ({ ...current, amount: event.target.value }))}
                  />
                </div>
              </div>
              <button className="button" onClick={() => void handleCreateManual()}>
                {t.addManualInvoice}
              </button>
            </div>
          </section>

          <section className="sidebarCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{extraCopy.factories}</h2>
              <span className="panelBadge">{factorySummaries.length}</span>
            </div>
            <p className="helperText sidebarHelperText">{extraCopy.factoryHint}</p>
            <div className="compactList">
              {visibleFactories.length ? (
                visibleFactories.map((factory) => (
                  <button
                    key={factory.name}
                    type="button"
                    className={`factoryCard ${factoryFilter === factory.name ? "active" : ""}`}
                    onClick={() => setFactoryFilter((current) => (current === factory.name ? ALL_FACTORIES_VALUE : factory.name))}
                  >
                    <div className="factoryLogo" aria-hidden="true">{getInitials(factory.name)}</div>
                    <div className="factoryCardCopy">
                      <div className="compactSupplierHead">
                        <strong>{factory.name}</strong>
                        <span>{factory.country ?? t.unknownCountry}</span>
                      </div>
                      <div className="supplierStats">
                        <span>{t.invoiceCount(factory.invoiceCount)}</span>
                        <span>{t.highRisk}: {factory.highRiskCount}</span>
                        <span>{t.openShort}: {formatCurrency(locale, factory.remainingAmount)}</span>
                      </div>
                    </div>
                  </button>
                ))
              ) : (
                <p className="helperText">{t.supplierIndexEmpty}</p>
              )}
            </div>
          </section>

          <div className="sidebarFooterMeta">
            <span>{t.lastSync}</span>
            <strong>{metrics?.latest_sync_at ? formatDateTime(locale, metrics.latest_sync_at) : t.unset}</strong>
          </div>
        </aside>

        <section className="surfaceMain">
          <header className="topbar">
            <div className="topbarLeft">
              <p className="eyebrow">{t.indexEyebrow}</p>
              <h1>Woodguard</h1>
              <p>{draft ? `${t.selectedInvoice}: ${draft.invoice_number}` : t.noInvoicesYet}</p>
            </div>

            <div className="topbarControls">
              <div className="topbarRow topbarRowPrimary">
                <label className="searchShell">
                  <span className="searchLabel">{t.search}</span>
                  <input
                    className="searchInput"
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder={t.searchPlaceholder}
                  />
                </label>
                <label className="filterShell">
                  <span className="filterLabel">{extraCopy.factoryFilter}</span>
                  <select className="filterSelect" value={factoryFilter} onChange={(event) => setFactoryFilter(event.target.value)}>
                    <option value={ALL_FACTORIES_VALUE}>{extraCopy.allFactories}</option>
                    {factorySummaries.map((factory) => (
                      <option key={factory.name} value={factory.name}>
                        {factory.name}
                      </option>
                    ))}
                  </select>
                </label>
                {languageSwitcher}
                {themeSwitcher}
              </div>
              <div className="topbarRow topbarRowSecondary">
                <button className="button secondary" onClick={() => void handleSync()} disabled={!canSync}>
                  {t.syncWarehub}
                </button>
                <button className="button secondary" onClick={() => void loadDashboard(selectedId)}>
                  {t.refresh}
                </button>
                <button className="button ghost" onClick={() => void handleLogout()}>
                  {t.logout}
                </button>
                <div className="userCard">
                  <div className="userAvatar">{userInitials}</div>
                  <div>
                    <strong>{userDisplayName}</strong>
                    <span>{translateRole(locale, currentUser.role)}</span>
                  </div>
                </div>
              </div>
            </div>
          </header>

          {statusMessage ? <div key={`${statusMessage.type}-${statusMessage.text}`} className={`statusBar ${statusMessage.type}`}>{statusMessage.text}</div> : null}

          <section className="metricGrid topMetricGrid">
            {dashboardStats.map((item) => (
              <article className="panel metricCard" key={item.label}>
                <span className="metricLabel">{item.label}</span>
                <strong>{item.value}</strong>
              </article>
            ))}
          </section>

          <div className="appTabs">
            {[
              { key: "overview" as const, label: t.overviewTab },
              { key: "evidence" as const, label: t.evidenceTab },
              { key: "analytics" as const, label: t.analyticsTab },
            ].map((item) => (
              <button
                key={item.key}
                type="button"
                className={`appTab ${activeTab === item.key ? "active" : ""}`}
                onClick={() => startTransition(() => setActiveTab(item.key))}
              >
                {item.label}
              </button>
            ))}
          </div>

          <div className="workspaceShell">
            <section className="contentMain" key={`workspace-${selectedId ?? "empty"}-${activeTab}`}>
              {renderWorkspace()}
            </section>

            <aside className="rightRail" key={`rail-${selectedId ?? "empty"}`}>
              <section className="panel railPanel">
                <div className="panelHead">
                  <h2 className="sectionTitle">{t.recentInvoices}</h2>
                  <span className="panelBadge">{filteredInvoices.length}</span>
                </div>
                <div className="recentList">
                  {recentInvoices.length ? (
                    recentInvoices.map((invoice) => (
                      <button
                        key={invoice.id}
                        type="button"
                        className={`recentItem ${selectedId === invoice.id ? "active" : ""}`}
                        onClick={() => void handleSelect(invoice.id)}
                      >
                        <div className="recentMeta">
                          <strong>{invoice.invoice_number}</strong>
                          <span>{invoice.company_name ?? t.unassignedSupplier}</span>
                        </div>
                        <div className="recentAside">
                          <span>{formatCurrency(locale, invoice.amount)}</span>
                          <span className={`pill ${invoice.risk.risk_level}`}>{translateRiskLevel(locale, invoice.risk.risk_level)}</span>
                        </div>
                      </button>
                    ))
                  ) : (
                    <p className="helperText">{t.recentInvoicesEmpty}</p>
                  )}
                </div>
              </section>

              <section className="panel railPanel">
                <div className="panelHead">
                  <h2 className="sectionTitle">{t.notifications}</h2>
                  <span className="panelBadge">{notificationItems.length}</span>
                </div>
                <div className="notificationList">
                  {notificationItems.length ? (
                    notificationItems.map((item) => (
                      <article className={`notificationItem ${item.tone}`} key={`${item.title}-${item.text}`}>
                        <strong>{item.title}</strong>
                        <span>{item.text}</span>
                      </article>
                    ))
                  ) : (
                    <p className="helperText">{t.noAuditActivity}</p>
                  )}
                </div>
              </section>

              <section className="panel railPanel">
                <div className="panelHead">
                  <h2 className="sectionTitle">{t.latestActivity}</h2>
                  <span className="panelBadge">{auditLogs.length}</span>
                </div>
                <div className="compactList">
                  {auditLogs.slice(0, 4).map((entry) => (
                    <article className="compactAudit" key={entry.id}>
                      <div>
                        <strong>{translateAuditAction(locale, entry.action)}</strong>
                        <span>{entry.actor_username ?? t.systemActor}</span>
                      </div>
                      <span>{formatDateTime(locale, entry.created_at)}</span>
                    </article>
                  ))}
                  {!auditLogs.length ? <p className="helperText">{t.noAuditActivity}</p> : null}
                </div>
              </section>
            </aside>
          </div>
        </section>
      </section>
    </main>
  );
}
