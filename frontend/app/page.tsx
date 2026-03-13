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
  storeTokens,
  syncWarehub,
  updateAssessment,
  updateInvoice,
  uploadFile,
  type InvoiceCreatePayload,
  type InvoiceMetadataPayload,
} from "../lib/api";
import {
  DEFAULT_LOCALE,
  LOCALE_LABELS,
  SUPPORTED_LOCALES,
  detectPreferredLocale,
  formatCurrency,
  formatDateTime,
  formatPercent,
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
import { RiskRing } from "./risk-ring";


const EVIDENCE_SECTIONS = [
  "certificate",
  "location_pictures",
  "notice",
  "transport_papers",
  "geolocation_screenshot",
  "others",
] as const;

const STATUS_OPTIONS = ["pending", "partial", "paid", "cancelled", "draft", "unknown"];

type EvidenceKey = (typeof EVIDENCE_SECTIONS)[number];
type ThemeMode = "light" | "dark";
type WorkspaceTab = "overview" | "evidence" | "analytics";

const THEME_STORAGE_KEY = "woodguard_theme";


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
  const deferredSearch = useDeferredValue(search);
  const [statusMessage, setStatusMessage] = useState<{ type: "error" | "info"; text: string } | null>(null);
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

  const filteredInvoices = invoices.filter((invoice) => {
    if (!deferredSearch.trim()) {
      return true;
    }
    const haystack = `${invoice.invoice_number} ${invoice.company_name ?? ""} ${invoice.seller_name ?? ""}`.toLowerCase();
    return haystack.includes(deferredSearch.toLowerCase());
  });

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

    try {
      setStatusMessage({ type: "info", text: t.autoDetectLocation });
      const updated = await autofillGeolocation(draft.id);
      setDraft(updated);
      const audit = await getInvoiceAuditLogs(draft.id);
      setAuditLogs(audit.items);
      setStatusMessage({ type: "info", text: t.dossierSaved });
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
        <p className="helperText">{t.indexDescription}</p>
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
              <button className="button secondary" onClick={() => void handleAutofillGeolocation()}>
                {t.autoDetectLocation}
              </button>
            </div>
          </article>
        </section>

        <section className="dashboardPanels bottomPanels">
          <article className="panel cardBody geoCard">
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

          <article className="panel cardBody insightCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.notifications}</h2>
              <span className="panelBadge">{t.latestActivity}</span>
            </div>
            <div className="notificationList">
              {notificationItems.map((item) => (
                <article className={`notificationItem ${item.tone}`} key={`${item.title}-${item.text}`}>
                  <strong>{item.title}</strong>
                  <span>{item.text}</span>
                </article>
              ))}
            </div>
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
            <strong>{latestAuditEntry ? formatDateTime(locale, latestAuditEntry.created_at) : t.unset}</strong>
          </article>
        </section>

        <section className="dashboardPanels">
          <article className="panel cardBody formCard">
            <div className="panelHead">
              <h2 className="sectionTitle">{t.riskInputs}</h2>
              <span className="panelBadge">{t.analyticsTab}</span>
            </div>
            <div className="stack">
              <div className="gridTwo">
                <div className="formRow">
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
                <div className="formRow">
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
                <div className="formRow">
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
                <div className="formRow">
                  <label>{t.geolocationSource}</label>
                  <input
                    className="textInput"
                    value={draft.assessment.geolocation_source_text ?? ""}
                    onChange={(event) => setAssessmentValue("geolocation_source_text", event.target.value || null)}
                  />
                </div>
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
                  <article className="notificationItem high" key={blocker}>
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
                {statusMessage ? <div className={`statusBar ${statusMessage.type}`}>{statusMessage.text}</div> : null}
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
  const visibleSuppliers = metrics?.suppliers.slice(0, 5) ?? [];
  const dashboardStats = metrics
    ? [
        { label: t.invoices, value: metrics.total_invoices.toString() },
        { label: t.openExposure, value: formatCurrency(locale, metrics.open_exposure) },
        { label: t.coverageAverage, value: formatPercent(locale, metrics.average_coverage) },
        { label: t.highRisk, value: metrics.high_risk_count.toString() },
      ]
    : [];

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
                onClick={() => setActiveTab(item.key)}
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
              <h2 className="sectionTitle">{t.indexCompaniesNoEu}</h2>
              <span className="panelBadge">{metrics?.suppliers.length ?? 0}</span>
            </div>
            <div className="compactList">
              {visibleSuppliers.length ? (
                visibleSuppliers.map((supplier) => (
                  <article className="compactSupplier" key={supplier.name}>
                    <div className="compactSupplierHead">
                      <strong>{supplier.name}</strong>
                      <span>{supplier.country ?? t.unknownCountry}</span>
                    </div>
                    <div className="supplierStats">
                      <span>{t.highRisk}: {supplier.high_risk_count}</span>
                      <span>{t.openShort}: {formatCurrency(locale, supplier.remaining_amount)}</span>
                    </div>
                  </article>
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

          {statusMessage ? <div className={`statusBar ${statusMessage.type}`}>{statusMessage.text}</div> : null}

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
                onClick={() => setActiveTab(item.key)}
              >
                {item.label}
              </button>
            ))}
          </div>

          <div className="workspaceShell">
            <section className="contentMain">{renderWorkspace()}</section>

            <aside className="rightRail">
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
