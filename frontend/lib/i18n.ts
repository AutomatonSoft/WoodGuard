import type { ComplianceChoice, DocumentStatus, RiskLevel, UserPublic } from "./types";


export const SUPPORTED_LOCALES = ["en", "ru", "de"] as const;
export type Locale = (typeof SUPPORTED_LOCALES)[number];

export const DEFAULT_LOCALE: Locale = "en";

const LOCALE_STORAGE_KEY = "woodguard_locale";

const INTL_LOCALE: Record<Locale, string> = {
  en: "en-US",
  ru: "ru-RU",
  de: "de-DE",
};

export const LOCALE_LABELS: Record<Locale, string> = {
  en: "English",
  ru: "Русский",
  de: "Deutsch",
};

type UiMessages = {
  language: string;
  theme: string;
  light: string;
  dark: string;
  checkingSession: string;
  authEyebrow: string;
  authTitle: string;
  authDescription: string;
  defaultAdminNote: string;
  usernameOrEmail: string;
  password: string;
  signIn: string;
  indexEyebrow: string;
  indexTitle: string;
  indexDescription: string;
  syncWarehub: string;
  refresh: string;
  logout: string;
  invoices: string;
  openExposure: string;
  coverageAverage: string;
  highRisk: string;
  nonEuSuppliers: string;
  paid: string;
  createNewIndex: string;
  invoiceNumber: string;
  companyName: string;
  country: string;
  amount: string;
  addManualInvoice: string;
  indexCompaniesNoEu: string;
  supplierIndexEmpty: string;
  unknownCountry: string;
  invoiceQueue: string;
  overviewTab: string;
  evidenceTab: string;
  analyticsTab: string;
  recentInvoices: string;
  recentInvoicesEmpty: string;
  notifications: string;
  riskScore: string;
  pendingEvidence: string;
  uploadedEvidence: string;
  verifiedSections: string;
  geoSnapshot: string;
  mapPreview: string;
  coordinates: string;
  autoDetectLocation: string;
  useCurrentLocation: string;
  useCurrentLocationDescription: string;
  currentLocationStatus: string;
  currentLocationSavedDraft: string;
  currentLocationCoordinatesOnly: string;
  currentLocationUnavailable: string;
  currentLocationPermissionDenied: string;
  openMap: string;
  lastSync: string;
  selectedInvoice: string;
  latestActivity: string;
  search: string;
  searchPlaceholder: string;
  unassignedSupplier: string;
  orderHubInvoice: string;
  manualIndex: string;
  invoice: string;
  paidShort: string;
  openShort: string;
  invoiceMetadata: string;
  selectCountry: string;
  status: string;
  remainingAmount: string;
  invoiceDate: string;
  dueDate: string;
  productionDate: string;
  importDate: string;
  internalNotes: string;
  sellerCard: string;
  sellerName: string;
  address: string;
  phone: string;
  email: string;
  website: string;
  contactPerson: string;
  geolocationLabel: string;
  latitude: string;
  longitude: string;
  evidenceSections: string;
  memo: string;
  upload: string;
  woodSpecification: string;
  woodSpecies: string;
  materialTypes: string;
  woodSpecificationMemo: string;
  countryOfOrigin: string;
  deliveryDate: string;
  quantity: string;
  unit: string;
  riskInputs: string;
  childLabor: string;
  humanRights: string;
  geoLatitude: string;
  geoLongitude: string;
  geolocationSource: string;
  personalRiskAssessment: string;
  why: string;
  coverage: string;
  penalties: string;
  riskBlockers: string;
  saveDossier: string;
  saveDossierDescription: string;
  saveInvoiceDossier: string;
  auditTrail: string;
  actor: string;
  systemActor: string;
  noAuditActivity: string;
  noSummaryProvided: string;
  noInvoicesYet: string;
  currentFiles: string;
  unset: string;
  roleSeparator: string;
  signedInAs: (username: string) => string;
  signingIn: string;
  syncingWarehubStatus: string;
  warehubSyncCompleted: string;
  warehubSyncFailed: string;
  manualInvoiceNumberRequired: string;
  manualInvoiceCreated: string;
  fileUploadFailed: string;
  saveDossierStatus: string;
  dossierSaved: string;
  loginFailed: string;
  signedOut: string;
  loadDashboardFailed: string;
  loadInvoiceFailed: string;
  createInvoiceFailed: string;
  saveInvoiceFailed: string;
  uploadedFiles: (count: number, backend: string) => string;
  invoicesInView: (count: number) => string;
  invoiceCount: (count: number) => string;
  supplierRiskOpen: (count: number, exposure: string) => string;
};

const UI_MESSAGES: Record<Locale, UiMessages> = {
  en: {
    language: "Language",
    theme: "Theme",
    light: "Light",
    dark: "Dark",
    checkingSession: "Checking session...",
    authEyebrow: "Woodguard / Auth",
    authTitle: "Sign in to manage invoice dossiers and risk reviews.",
    authDescription: "Use the local bootstrap admin only for testing. Switch credentials before real use.",
    defaultAdminNote: "Default local bootstrap admin: admin / woodguard123.",
    usernameOrEmail: "Username or Email",
    password: "Password",
    signIn: "Sign In",
    indexEyebrow: "Woodguard / Index",
    indexTitle: "Pull Warehub invoices, capture timber evidence, score risk, and keep one dossier per invoice.",
    indexDescription: "Warehub brings invoice finance facts. Woodguard stores supplier context, uploads, geolocation proof, wood specification and the final human judgement.",
    syncWarehub: "Sync Warehub",
    refresh: "Refresh",
    logout: "Logout",
    invoices: "Invoices",
    openExposure: "Open Exposure",
    coverageAverage: "Coverage Avg",
    highRisk: "High Risk",
    nonEuSuppliers: "Non-EU Suppliers",
    paid: "Paid",
    createNewIndex: "Create New Index",
    invoiceNumber: "Invoice Number",
    companyName: "Company Name",
    country: "Country",
    amount: "Amount",
    addManualInvoice: "Add Manual Invoice",
    indexCompaniesNoEu: "Index Companies No EU",
    supplierIndexEmpty: "Supplier index will appear after the first sync or manual creation.",
    unknownCountry: "Unknown country",
    invoiceQueue: "Invoice Queue",
    overviewTab: "Overview",
    evidenceTab: "Evidence",
    analyticsTab: "Analytics",
    recentInvoices: "Recent Invoices",
    recentInvoicesEmpty: "No invoices available in the current filter.",
    notifications: "Notifications",
    riskScore: "Risk Score",
    pendingEvidence: "Pending Evidence",
    uploadedEvidence: "Uploaded Evidence",
    verifiedSections: "Verified Sections",
    geoSnapshot: "Geo Snapshot",
    mapPreview: "Map Preview",
    coordinates: "Coordinates",
    autoDetectLocation: "Auto Detect Location",
    useCurrentLocation: "Use Current Location",
    useCurrentLocationDescription: "Uses the browser location, fills the draft address and coordinates, then waits for your save.",
    currentLocationStatus: "Detecting current location...",
    currentLocationSavedDraft: "Current location loaded into the draft. Review and save to confirm.",
    currentLocationCoordinatesOnly: "Current coordinates loaded into the draft. Address lookup failed, so review before saving.",
    currentLocationUnavailable: "Browser geolocation is not available here.",
    currentLocationPermissionDenied: "Location permission was denied.",
    openMap: "Open Map",
    lastSync: "Last Sync",
    selectedInvoice: "Selected Invoice",
    latestActivity: "Latest Activity",
    search: "Search",
    searchPlaceholder: "Invoice / company / seller",
    unassignedSupplier: "Unassigned supplier",
    orderHubInvoice: "Order Hub Invoice",
    manualIndex: "Manual Index",
    invoice: "Invoice",
    paidShort: "Paid",
    openShort: "Open",
    invoiceMetadata: "Invoice Metadata",
    selectCountry: "Select country",
    status: "Status",
    remainingAmount: "Remaining Amount",
    invoiceDate: "Invoice Date",
    dueDate: "Due Date",
    productionDate: "Production Date",
    importDate: "Import Date",
    internalNotes: "Internal Notes",
    sellerCard: "Seller Card",
    sellerName: "Seller Name",
    address: "Address",
    phone: "Phone",
    email: "Email",
    website: "Website",
    contactPerson: "Contact Person",
    geolocationLabel: "Geolocation Label",
    latitude: "Latitude",
    longitude: "Longitude",
    evidenceSections: "Evidence Sections",
    memo: "Memo",
    upload: "Upload",
    woodSpecification: "Wood Specification",
    woodSpecies: "Wood Species",
    materialTypes: "Material Types",
    woodSpecificationMemo: "Wood Specification Memo",
    countryOfOrigin: "Country of Origin",
    deliveryDate: "Delivery Date",
    quantity: "Quantity",
    unit: "Unit",
    riskInputs: "Risk Inputs",
    childLabor: "Child Labor",
    humanRights: "Human Rights",
    geoLatitude: "Geo Latitude",
    geoLongitude: "Geo Longitude",
    geolocationSource: "Geolocation Source",
    personalRiskAssessment: "Personal Risk Assessment",
    why: "Why?",
    coverage: "Coverage",
    penalties: "Penalties",
    riskBlockers: "Risk Blockers",
    saveDossier: "Save Dossier",
    saveDossierDescription: "Save writes supplier metadata and due diligence assessment back into Woodguard.",
    saveInvoiceDossier: "Save Invoice Dossier",
    auditTrail: "Audit Trail",
    actor: "Actor",
    systemActor: "system",
    noAuditActivity: "No audit activity recorded for this invoice yet.",
    noSummaryProvided: "No summary provided.",
    noInvoicesYet: "No invoices yet. Sync Warehub or create the first manual index to start.",
    currentFiles: "Current files",
    unset: "Unset",
    roleSeparator: "|",
    signedInAs: (username) => `Signed in as ${username}.`,
    signingIn: "Signing in...",
    syncingWarehubStatus: "Syncing Warehub invoices...",
    warehubSyncCompleted: "Warehub sync completed.",
    warehubSyncFailed: "Warehub sync failed.",
    manualInvoiceNumberRequired: "Manual invoice number is required.",
    manualInvoiceCreated: "Manual invoice dossier created.",
    fileUploadFailed: "File upload failed.",
    saveDossierStatus: "Saving Woodguard dossier...",
    dossierSaved: "Invoice dossier saved.",
    loginFailed: "Login failed.",
    signedOut: "Signed out.",
    loadDashboardFailed: "Failed to load dashboard.",
    loadInvoiceFailed: "Failed to load invoice.",
    createInvoiceFailed: "Failed to create manual invoice.",
    saveInvoiceFailed: "Failed to save invoice dossier.",
    uploadedFiles: (count, backend) => `${count} file(s) uploaded to ${backend}.`,
    invoicesInView: (count) => `${count} invoice dossier(s) in the current view.`,
    invoiceCount: (count) => `${count} invoice(s)`,
    supplierRiskOpen: (count, exposure) => `High risk: ${count} | Open: ${exposure}`,
  },
  ru: {
    language: "Язык",
    theme: "Тема",
    light: "Светлая",
    dark: "Темная",
    checkingSession: "Проверка сессии...",
    authEyebrow: "Woodguard / Вход",
    authTitle: "Войдите, чтобы управлять досье по инвойсам и оценкой рисков.",
    authDescription: "Локального bootstrap admin используйте только для тестов. Для реальной работы смените доступы.",
    defaultAdminNote: "Локальный bootstrap admin по умолчанию: admin / woodguard123.",
    usernameOrEmail: "Логин или Email",
    password: "Пароль",
    signIn: "Войти",
    indexEyebrow: "Woodguard / Индекс",
    indexTitle: "Подтягивайте инвойсы из Warehub, собирайте timber evidence, считайте риск и храните отдельное досье на каждый инвойс.",
    indexDescription: "Warehub дает финансовые данные по инвойсу. Woodguard хранит контекст поставщика, файлы, геолокацию, спецификацию древесины и итоговую ручную оценку.",
    syncWarehub: "Синхронизировать Warehub",
    refresh: "Обновить",
    logout: "Выйти",
    invoices: "Инвойсы",
    openExposure: "Открытая сумма",
    coverageAverage: "Среднее покрытие",
    highRisk: "Высокий риск",
    nonEuSuppliers: "Поставщики вне ЕС",
    paid: "Оплачено",
    createNewIndex: "Создать новый индекс",
    invoiceNumber: "Номер инвойса",
    companyName: "Название компании",
    country: "Страна",
    amount: "Сумма",
    addManualInvoice: "Добавить инвойс вручную",
    indexCompaniesNoEu: "Индекс компаний вне ЕС",
    supplierIndexEmpty: "Индекс поставщиков появится после первой синхронизации или ручного создания.",
    unknownCountry: "Страна не указана",
    invoiceQueue: "Очередь инвойсов",
    overviewTab: "Обзор",
    evidenceTab: "Доказательства",
    analyticsTab: "Аналитика",
    recentInvoices: "Последние инвойсы",
    recentInvoicesEmpty: "В текущем фильтре нет инвойсов.",
    notifications: "Уведомления",
    riskScore: "Оценка риска",
    pendingEvidence: "Ожидающие доказательства",
    uploadedEvidence: "Загруженные файлы",
    verifiedSections: "Проверенные разделы",
    geoSnapshot: "Гео-снимок",
    mapPreview: "Предпросмотр карты",
    coordinates: "Координаты",
    autoDetectLocation: "Определить геолокацию",
    useCurrentLocation: "Использовать текущую локацию",
    useCurrentLocationDescription: "Берет геопозицию браузера, подставляет адрес и координаты в черновик и ждет вашего сохранения.",
    currentLocationStatus: "Определяем текущую локацию...",
    currentLocationSavedDraft: "Текущая локация подставлена в черновик. Проверьте и сохраните для подтверждения.",
    currentLocationCoordinatesOnly: "Координаты текущей локации подставлены в черновик. Адрес не удалось определить, проверьте перед сохранением.",
    currentLocationUnavailable: "Геолокация браузера здесь недоступна.",
    currentLocationPermissionDenied: "Доступ к геолокации запрещен.",
    openMap: "Открыть карту",
    lastSync: "Последняя синхронизация",
    selectedInvoice: "Выбранный инвойс",
    latestActivity: "Последняя активность",
    search: "Поиск",
    searchPlaceholder: "Инвойс / компания / продавец",
    unassignedSupplier: "Поставщик не назначен",
    orderHubInvoice: "Инвойс Order Hub",
    manualIndex: "Ручной индекс",
    invoice: "Инвойс",
    paidShort: "Оплачено",
    openShort: "Остаток",
    invoiceMetadata: "Метаданные инвойса",
    selectCountry: "Выберите страну",
    status: "Статус",
    remainingAmount: "Оставшаяся сумма",
    invoiceDate: "Дата инвойса",
    dueDate: "Срок оплаты",
    productionDate: "Дата производства",
    importDate: "Дата импорта",
    internalNotes: "Внутренние заметки",
    sellerCard: "Карточка продавца",
    sellerName: "Название продавца",
    address: "Адрес",
    phone: "Телефон",
    email: "Email",
    website: "Сайт",
    contactPerson: "Контактное лицо",
    geolocationLabel: "Подпись геолокации",
    latitude: "Широта",
    longitude: "Долгота",
    evidenceSections: "Разделы доказательств",
    memo: "Комментарий",
    upload: "Загрузка",
    woodSpecification: "Спецификация древесины",
    woodSpecies: "Породы древесины",
    materialTypes: "Типы материалов",
    woodSpecificationMemo: "Комментарий по спецификации",
    countryOfOrigin: "Страна происхождения",
    deliveryDate: "Дата поставки",
    quantity: "Количество",
    unit: "Единица",
    riskInputs: "Поля оценки риска",
    childLabor: "Детский труд",
    humanRights: "Права человека",
    geoLatitude: "Гео широта",
    geoLongitude: "Гео долгота",
    geolocationSource: "Источник геоданных",
    personalRiskAssessment: "Ручная оценка риска",
    why: "Почему?",
    coverage: "Покрытие",
    penalties: "Штрафные баллы",
    riskBlockers: "Блокеры риска",
    saveDossier: "Сохранение досье",
    saveDossierDescription: "Сохранение записывает метаданные поставщика и due diligence assessment обратно в Woodguard.",
    saveInvoiceDossier: "Сохранить досье инвойса",
    auditTrail: "Журнал действий",
    actor: "Кто сделал",
    systemActor: "система",
    noAuditActivity: "По этому инвойсу пока нет записанных действий.",
    noSummaryProvided: "Описание не указано.",
    noInvoicesYet: "Инвойсов пока нет. Синхронизируйте Warehub или создайте первый индекс вручную.",
    currentFiles: "Текущие файлы",
    unset: "Не задано",
    roleSeparator: "|",
    signedInAs: (username) => `Вход выполнен: ${username}.`,
    signingIn: "Выполняется вход...",
    syncingWarehubStatus: "Синхронизация инвойсов Warehub...",
    warehubSyncCompleted: "Синхронизация Warehub завершена.",
    warehubSyncFailed: "Ошибка синхронизации Warehub.",
    manualInvoiceNumberRequired: "Номер ручного инвойса обязателен.",
    manualInvoiceCreated: "Ручное досье по инвойсу создано.",
    fileUploadFailed: "Ошибка загрузки файла.",
    saveDossierStatus: "Сохранение досье Woodguard...",
    dossierSaved: "Досье по инвойсу сохранено.",
    loginFailed: "Не удалось выполнить вход.",
    signedOut: "Вы вышли из системы.",
    loadDashboardFailed: "Не удалось загрузить дашборд.",
    loadInvoiceFailed: "Не удалось загрузить инвойс.",
    createInvoiceFailed: "Не удалось создать ручной инвойс.",
    saveInvoiceFailed: "Не удалось сохранить досье по инвойсу.",
    uploadedFiles: (count, backend) => `Загружено файлов: ${count}. Хранилище: ${backend}.`,
    invoicesInView: (count) => `В текущем списке досье: ${count}.`,
    invoiceCount: (count) => `${count} инвойс(ов)`,
    supplierRiskOpen: (count, exposure) => `Высокий риск: ${count} | Остаток: ${exposure}`,
  },
  de: {
    language: "Sprache",
    theme: "Thema",
    light: "Hell",
    dark: "Dunkel",
    checkingSession: "Sitzung wird geprüft...",
    authEyebrow: "Woodguard / Anmeldung",
    authTitle: "Anmelden, um Rechnungsdossiers und Risikoprüfungen zu verwalten.",
    authDescription: "Den lokalen Bootstrap-Admin nur für Tests verwenden. Vor echtem Einsatz Zugangsdaten ändern.",
    defaultAdminNote: "Lokaler Bootstrap-Admin standardmäßig: admin / woodguard123.",
    usernameOrEmail: "Benutzername oder E-Mail",
    password: "Passwort",
    signIn: "Anmelden",
    indexEyebrow: "Woodguard / Index",
    indexTitle: "Warehub-Rechnungen laden, Nachweise erfassen, Risiko bewerten und pro Rechnung ein Dossier führen.",
    indexDescription: "Warehub liefert die finanziellen Rechnungsdaten. Woodguard speichert Lieferantenkontext, Uploads, Geolokation, Holzspezifikation und die finale manuelle Bewertung.",
    syncWarehub: "Warehub synchronisieren",
    refresh: "Aktualisieren",
    logout: "Abmelden",
    invoices: "Rechnungen",
    openExposure: "Offener Betrag",
    coverageAverage: "Durchschn. Abdeckung",
    highRisk: "Hohes Risiko",
    nonEuSuppliers: "Lieferanten außerhalb der EU",
    paid: "Bezahlt",
    createNewIndex: "Neuen Index anlegen",
    invoiceNumber: "Rechnungsnummer",
    companyName: "Firmenname",
    country: "Land",
    amount: "Betrag",
    addManualInvoice: "Manuelle Rechnung anlegen",
    indexCompaniesNoEu: "Index Unternehmen außerhalb der EU",
    supplierIndexEmpty: "Der Lieferantenindex erscheint nach der ersten Synchronisierung oder manuellen Anlage.",
    unknownCountry: "Unbekanntes Land",
    invoiceQueue: "Rechnungswarteschlange",
    overviewTab: "Übersicht",
    evidenceTab: "Nachweise",
    analyticsTab: "Analytik",
    recentInvoices: "Letzte Rechnungen",
    recentInvoicesEmpty: "Keine Rechnungen im aktuellen Filter.",
    notifications: "Benachrichtigungen",
    riskScore: "Risikoscore",
    pendingEvidence: "Offene Nachweise",
    uploadedEvidence: "Hochgeladene Dateien",
    verifiedSections: "Verifizierte Bereiche",
    geoSnapshot: "Geo-Snapshot",
    mapPreview: "Kartenvorschau",
    coordinates: "Koordinaten",
    autoDetectLocation: "Standort automatisch bestimmen",
    useCurrentLocation: "Aktuellen Standort verwenden",
    useCurrentLocationDescription: "Nutzt den Browser-Standort, fuellt Adresse und Koordinaten in den Entwurf und wartet dann auf Ihr Speichern.",
    currentLocationStatus: "Aktueller Standort wird bestimmt...",
    currentLocationSavedDraft: "Der aktuelle Standort wurde in den Entwurf uebernommen. Bitte pruefen und mit Speichern bestaetigen.",
    currentLocationCoordinatesOnly: "Die aktuellen Koordinaten wurden in den Entwurf uebernommen. Die Adresse konnte nicht aufgeloest werden, bitte vor dem Speichern pruefen.",
    currentLocationUnavailable: "Browser-Geolokation ist hier nicht verfuegbar.",
    currentLocationPermissionDenied: "Der Zugriff auf die Geolokation wurde verweigert.",
    openMap: "Karte öffnen",
    lastSync: "Letzte Synchronisierung",
    selectedInvoice: "Ausgewählte Rechnung",
    latestActivity: "Letzte Aktivität",
    search: "Suche",
    searchPlaceholder: "Rechnung / Firma / Verkäufer",
    unassignedSupplier: "Kein Lieferant zugewiesen",
    orderHubInvoice: "Order-Hub-Rechnung",
    manualIndex: "Manueller Index",
    invoice: "Rechnung",
    paidShort: "Bezahlt",
    openShort: "Offen",
    invoiceMetadata: "Rechnungsmetadaten",
    selectCountry: "Land auswählen",
    status: "Status",
    remainingAmount: "Restbetrag",
    invoiceDate: "Rechnungsdatum",
    dueDate: "Fälligkeitsdatum",
    productionDate: "Produktionsdatum",
    importDate: "Importdatum",
    internalNotes: "Interne Notizen",
    sellerCard: "Verkäuferprofil",
    sellerName: "Verkäufername",
    address: "Adresse",
    phone: "Telefon",
    email: "E-Mail",
    website: "Webseite",
    contactPerson: "Kontaktperson",
    geolocationLabel: "Geolokationsbezeichnung",
    latitude: "Breitengrad",
    longitude: "Längengrad",
    evidenceSections: "Nachweisbereiche",
    memo: "Notiz",
    upload: "Upload",
    woodSpecification: "Holzspezifikation",
    woodSpecies: "Holzarten",
    materialTypes: "Materialtypen",
    woodSpecificationMemo: "Notiz zur Holzspezifikation",
    countryOfOrigin: "Ursprungsland",
    deliveryDate: "Lieferdatum",
    quantity: "Menge",
    unit: "Einheit",
    riskInputs: "Risikoeingaben",
    childLabor: "Kinderarbeit",
    humanRights: "Menschenrechte",
    geoLatitude: "Geo-Breitengrad",
    geoLongitude: "Geo-Längengrad",
    geolocationSource: "Geolokationsquelle",
    personalRiskAssessment: "Manuelle Risikoeinschätzung",
    why: "Warum?",
    coverage: "Abdeckung",
    penalties: "Strafpunkte",
    riskBlockers: "Risikoblocker",
    saveDossier: "Dossier speichern",
    saveDossierDescription: "Speichern schreibt Lieferantenmetadaten und die Due-Diligence-Bewertung zurück in Woodguard.",
    saveInvoiceDossier: "Rechnungsdossier speichern",
    auditTrail: "Audit-Protokoll",
    actor: "Akteur",
    systemActor: "System",
    noAuditActivity: "Für diese Rechnung wurden noch keine Aktionen protokolliert.",
    noSummaryProvided: "Keine Beschreibung vorhanden.",
    noInvoicesYet: "Noch keine Rechnungen. Warehub synchronisieren oder den ersten manuellen Index anlegen.",
    currentFiles: "Aktuelle Dateien",
    unset: "Nicht gesetzt",
    roleSeparator: "|",
    signedInAs: (username) => `Angemeldet als ${username}.`,
    signingIn: "Anmeldung läuft...",
    syncingWarehubStatus: "Warehub-Rechnungen werden synchronisiert...",
    warehubSyncCompleted: "Warehub-Synchronisierung abgeschlossen.",
    warehubSyncFailed: "Warehub-Synchronisierung fehlgeschlagen.",
    manualInvoiceNumberRequired: "Die manuelle Rechnungsnummer ist erforderlich.",
    manualInvoiceCreated: "Manuelles Rechnungsdossier wurde erstellt.",
    fileUploadFailed: "Datei-Upload fehlgeschlagen.",
    saveDossierStatus: "Woodguard-Dossier wird gespeichert...",
    dossierSaved: "Rechnungsdossier gespeichert.",
    loginFailed: "Anmeldung fehlgeschlagen.",
    signedOut: "Abgemeldet.",
    loadDashboardFailed: "Dashboard konnte nicht geladen werden.",
    loadInvoiceFailed: "Rechnung konnte nicht geladen werden.",
    createInvoiceFailed: "Manuelle Rechnung konnte nicht erstellt werden.",
    saveInvoiceFailed: "Rechnungsdossier konnte nicht gespeichert werden.",
    uploadedFiles: (count, backend) => `${count} Datei(en) in ${backend} hochgeladen.`,
    invoicesInView: (count) => `${count} Rechnungsdossier(s) in der aktuellen Ansicht.`,
    invoiceCount: (count) => `${count} Rechnung(en)`,
    supplierRiskOpen: (count, exposure) => `Hohes Risiko: ${count} | Offen: ${exposure}`,
  },
};

function titleize(value: string): string {
  return value
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

const RISK_LEVEL_LABELS: Record<Locale, Record<RiskLevel, string>> = {
  en: { low: "Low", medium: "Medium", high: "High" },
  ru: { low: "Низкий", medium: "Средний", high: "Высокий" },
  de: { low: "Niedrig", medium: "Mittel", high: "Hoch" },
};

const DOCUMENT_STATUS_LABELS: Record<Locale, Record<DocumentStatus, string>> = {
  en: { missing: "Missing", uploaded: "Uploaded", verified: "Verified" },
  ru: { missing: "Нет", uploaded: "Загружено", verified: "Проверено" },
  de: { missing: "Fehlt", uploaded: "Hochgeladen", verified: "Verifiziert" },
};

const COMPLIANCE_LABELS: Record<Locale, Record<ComplianceChoice, string>> = {
  en: { yes: "Yes", no: "No", unknown: "Unknown" },
  ru: { yes: "Да", no: "Нет", unknown: "Неизвестно" },
  de: { yes: "Ja", no: "Nein", unknown: "Unbekannt" },
};

const ROLE_LABELS: Record<Locale, Record<UserPublic["role"], string>> = {
  en: { admin: "Admin", analyst: "Analyst", reviewer: "Reviewer", viewer: "Viewer" },
  ru: { admin: "Админ", analyst: "Аналитик", reviewer: "Ревьюер", viewer: "Наблюдатель" },
  de: { admin: "Admin", analyst: "Analyst", reviewer: "Prüfer", viewer: "Betrachter" },
};

const INVOICE_STATUS_LABELS: Record<Locale, Record<string, string>> = {
  en: { pending: "Pending", partial: "Partial", paid: "Paid", cancelled: "Cancelled", draft: "Draft", unknown: "Unknown" },
  ru: { pending: "В ожидании", partial: "Частично", paid: "Оплачен", cancelled: "Отменен", draft: "Черновик", unknown: "Неизвестно" },
  de: { pending: "Ausstehend", partial: "Teilweise", paid: "Bezahlt", cancelled: "Storniert", draft: "Entwurf", unknown: "Unbekannt" },
};

const EVIDENCE_SECTION_LABELS: Record<Locale, Record<string, string>> = {
  en: {
    certificate: "Certificate",
    location_pictures: "Location Pictures",
    notice: "Notice",
    transport_papers: "Transport Papers",
    geolocation_screenshot: "Geolocation Screenshot",
    others: "Other Evidence",
  },
  ru: {
    certificate: "Сертификат",
    location_pictures: "Фото локации",
    notice: "Уведомление",
    transport_papers: "Транспортные документы",
    geolocation_screenshot: "Скриншот геолокации",
    others: "Прочие доказательства",
  },
  de: {
    certificate: "Zertifikat",
    location_pictures: "Standortfotos",
    notice: "Hinweis",
    transport_papers: "Transportdokumente",
    geolocation_screenshot: "Geolokations-Screenshot",
    others: "Weitere Nachweise",
  },
};

const WOOD_SPECIES_LABELS: Record<Locale, Record<string, string>> = {
  en: { oak: "Oak", beech: "Beech", pine: "Pine", spruce: "Spruce", ash: "Ash", maple: "Maple", birch: "Birch", walnut: "Walnut", cherry: "Cherry", mahogany: "Mahogany", teak: "Teak" },
  ru: { oak: "Дуб", beech: "Бук", pine: "Сосна", spruce: "Ель", ash: "Ясень", maple: "Клен", birch: "Береза", walnut: "Орех", cherry: "Вишня", mahogany: "Махагони", teak: "Тик" },
  de: { oak: "Eiche", beech: "Buche", pine: "Kiefer", spruce: "Fichte", ash: "Esche", maple: "Ahorn", birch: "Birke", walnut: "Walnuss", cherry: "Kirsche", mahogany: "Mahagoni", teak: "Teak" },
};

const MATERIAL_TYPE_LABELS: Record<Locale, Record<string, string>> = {
  en: { solid_wood: "Solid Wood", mdf: "MDF", hdf: "HDF", particle_board: "Particle Board", plywood: "Plywood", veneer: "Veneer", other: "Other" },
  ru: { solid_wood: "Массив дерева", mdf: "MDF", hdf: "HDF", particle_board: "ДСП", plywood: "Фанера", veneer: "Шпон", other: "Другое" },
  de: { solid_wood: "Massivholz", mdf: "MDF", hdf: "HDF", particle_board: "Spanplatte", plywood: "Sperrholz", veneer: "Furnier", other: "Andere" },
};

const BREAKDOWN_LABELS: Record<Locale, Record<string, string>> = {
  en: {
    "invoice.geolocation.autofill": "Geolocation Auto-Fill",
  },
  ru: {
    certificate_document: "Сертификат",
    certificate_memo: "Комментарий к сертификату",
    location_pictures_document: "Фото локации",
    location_pictures_memo: "Комментарий по локации",
    notice_document: "Уведомление",
    notice_memo: "Комментарий к уведомлению",
    wood_specification: "Спецификация древесины",
    country_of_origin: "Страна происхождения",
    quantity: "Количество",
    delivery_date: "Дата поставки",
    child_labor: "Ответ по детскому труду",
    human_rights: "Ответ по правам человека",
    geolocation_screenshot: "Скриншот геолокации",
    geolocation_data: "Данные геолокации",
    personal_risk_level: "Личная оценка риска",
    risk_reason: "Обоснование риска",
    others: "Прочие доказательства",
    transport_papers_document: "Транспортные документы",
    transport_papers_memo: "Комментарий по транспорту",
  },
  de: {
    certificate_document: "Zertifikat",
    certificate_memo: "Zertifikatsnotiz",
    location_pictures_document: "Standortfotos",
    location_pictures_memo: "Standortnotiz",
    notice_document: "Hinweis",
    notice_memo: "Hinweisnotiz",
    wood_specification: "Holzspezifikation",
    country_of_origin: "Ursprungsland",
    quantity: "Menge",
    delivery_date: "Lieferdatum",
    child_labor: "Antwort zu Kinderarbeit",
    human_rights: "Antwort zu Menschenrechten",
    geolocation_screenshot: "Geolokations-Screenshot",
    geolocation_data: "Geolokationsdaten",
    personal_risk_level: "Persönliche Risikobewertung",
    risk_reason: "Risikobegründung",
    others: "Weitere Nachweise",
    transport_papers_document: "Transportdokumente",
    transport_papers_memo: "Transportnotiz",
  },
};

const AUDIT_ACTION_LABELS: Record<Locale, Record<string, string>> = {
  en: {},
  ru: {
    "auth.login": "Вход",
    "auth.refresh": "Обновление токена",
    "auth.logout": "Выход",
    "user.create": "Создание пользователя",
    "user.update": "Обновление пользователя",
    "user.bootstrap_admin": "Создание bootstrap admin",
    "invoice.create": "Создание инвойса",
    "invoice.metadata.update": "Обновление метаданных",
    "invoice.assessment.update": "Обновление оценки",
    "invoice.sync.warehub": "Синхронизация Warehub",
    "upload.create": "Загрузка файла",
  },
  de: {
    "auth.login": "Anmeldung",
    "auth.refresh": "Token-Aktualisierung",
    "auth.logout": "Abmeldung",
    "user.create": "Benutzer angelegt",
    "user.update": "Benutzer aktualisiert",
    "user.bootstrap_admin": "Bootstrap-Admin angelegt",
    "invoice.create": "Rechnung angelegt",
    "invoice.metadata.update": "Metadaten aktualisiert",
    "invoice.assessment.update": "Bewertung aktualisiert",
    "invoice.geolocation.autofill": "Geolokation automatisch erkannt",
    "invoice.sync.warehub": "Warehub-Synchronisierung",
    "upload.create": "Datei hochgeladen",
  },
};

const STORAGE_BACKEND_LABELS: Record<Locale, Record<string, string>> = {
  en: { local: "local storage", s3: "S3 storage" },
  ru: { local: "локальное хранилище", s3: "S3-хранилище" },
  de: { local: "lokaler Speicher", s3: "S3-Speicher" },
};

export function getMessages(locale: Locale): UiMessages {
  return UI_MESSAGES[locale];
}

export function getStoredLocale(): Locale | null {
  if (typeof window === "undefined") {
    return null;
  }
  const value = window.localStorage.getItem(LOCALE_STORAGE_KEY);
  return value && SUPPORTED_LOCALES.includes(value as Locale) ? (value as Locale) : null;
}

export function detectPreferredLocale(): Locale {
  const stored = getStoredLocale();
  if (stored) {
    return stored;
  }
  if (typeof window === "undefined") {
    return DEFAULT_LOCALE;
  }
  const language = window.navigator.language.toLowerCase();
  if (language.startsWith("ru")) {
    return "ru";
  }
  if (language.startsWith("de")) {
    return "de";
  }
  return DEFAULT_LOCALE;
}

export function storeLocale(locale: Locale): void {
  if (typeof window === "undefined") {
    return;
  }
  window.localStorage.setItem(LOCALE_STORAGE_KEY, locale);
}

export function formatCurrency(locale: Locale, value: number): string {
  return new Intl.NumberFormat(INTL_LOCALE[locale], {
    style: "currency",
    currency: "EUR",
    maximumFractionDigits: 0,
  }).format(value);
}

export function formatPercent(locale: Locale, value: number): string {
  return `${new Intl.NumberFormat(INTL_LOCALE[locale], { maximumFractionDigits: 0 }).format(value)}%`;
}

export function formatDate(locale: Locale, value: string): string {
  return new Intl.DateTimeFormat(INTL_LOCALE[locale], {
    dateStyle: "medium",
  }).format(new Date(value));
}

export function formatTime(locale: Locale, value: string): string {
  return new Intl.DateTimeFormat(INTL_LOCALE[locale], {
    timeStyle: "short",
  }).format(new Date(value));
}

export function formatDateTime(locale: Locale, value: string): string {
  return new Intl.DateTimeFormat(INTL_LOCALE[locale], {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

export function translateRiskLevel(locale: Locale, value: RiskLevel): string {
  return RISK_LEVEL_LABELS[locale][value];
}

export function translateDocumentStatus(locale: Locale, value: DocumentStatus): string {
  return DOCUMENT_STATUS_LABELS[locale][value];
}

export function translateComplianceChoice(locale: Locale, value: ComplianceChoice): string {
  return COMPLIANCE_LABELS[locale][value];
}

export function translateInvoiceStatus(locale: Locale, value: string): string {
  return INVOICE_STATUS_LABELS[locale][value] ?? titleize(value);
}

export function translateRole(locale: Locale, value: UserPublic["role"]): string {
  return ROLE_LABELS[locale][value];
}

export function translateEvidenceSection(locale: Locale, value: string): string {
  return EVIDENCE_SECTION_LABELS[locale][value] ?? titleize(value);
}

export function translateWoodSpecies(locale: Locale, value: string): string {
  return WOOD_SPECIES_LABELS[locale][value] ?? titleize(value);
}

export function translateMaterialType(locale: Locale, value: string): string {
  return MATERIAL_TYPE_LABELS[locale][value] ?? titleize(value);
}

export function translateBreakdownLabel(locale: Locale, key: string, fallback: string): string {
  return BREAKDOWN_LABELS[locale][key] ?? fallback;
}

export function translateAuditAction(locale: Locale, value: string): string {
  return AUDIT_ACTION_LABELS[locale][value] ?? titleize(value.replace(/\./g, " "));
}

export function translateStorageBackend(locale: Locale, value: string): string {
  return STORAGE_BACKEND_LABELS[locale][value] ?? value;
}

export function translateBlocker(locale: Locale, blocker: string): string {
  if (locale === "en") {
    return blocker;
  }

  const euCountryMatch = blocker.match(/^Supplier country (.+) is outside the EU\.$/);
  if (euCountryMatch) {
    return locale === "ru"
      ? `Страна поставщика ${euCountryMatch[1]} находится вне ЕС.`
      : `Das Lieferland ${euCountryMatch[1]} liegt außerhalb der EU.`;
  }

  const staticMap: Record<string, Record<Exclude<Locale, "en">, string>> = {
    "Certificate is missing.": {
      ru: "Сертификат отсутствует.",
      de: "Das Zertifikat fehlt.",
    },
    "Transport papers are missing.": {
      ru: "Транспортные документы отсутствуют.",
      de: "Transportdokumente fehlen.",
    },
    "No geolocation proof attached.": {
      ru: "Нет подтверждения геолокации.",
      de: "Kein Geolokationsnachweis vorhanden.",
    },
    "Child labor concern flagged.": {
      ru: "Отмечен риск детского труда.",
      de: "Hinweis auf Kinderarbeit markiert.",
    },
    "Human rights concern flagged.": {
      ru: "Отмечен риск по правам человека.",
      de: "Hinweis auf Menschenrechtsrisiko markiert.",
    },
    "Reviewer marked this invoice as high risk.": {
      ru: "Ревьюер отметил этот инвойс как высокий риск.",
      de: "Der Prüfer hat diese Rechnung als hohes Risiko markiert.",
    },
    "Supplier country is unknown.": {
      ru: "Страна поставщика неизвестна.",
      de: "Das Lieferland ist unbekannt.",
    },
    "Wood origin country is not filled.": {
      ru: "Страна происхождения древесины не заполнена.",
      de: "Das Ursprungsland des Holzes ist nicht ausgefüllt.",
    },
  };

  return staticMap[blocker]?.[locale] ?? blocker;
}

export function translateAuditSummary(locale: Locale, summary: string | null): string | null {
  if (!summary || locale === "en") {
    return summary;
  }

  const patterns: Array<[RegExp, (...parts: string[]) => string]> = locale === "ru"
    ? [
        [/^User (.+) signed in\.$/, (name) => `Пользователь ${name} вошел в систему.`],
        [/^Refresh token rotated for (.+)\.$/, (name) => `Refresh token обновлен для ${name}.`],
        [/^Session signed out\.$/, () => "Сессия завершена."],
        [/^User (.+) created\.$/, (name) => `Пользователь ${name} создан.`],
        [/^User (.+) updated\.$/, (name) => `Пользователь ${name} обновлен.`],
        [/^Bootstrap admin (.+) created\.$/, (name) => `Bootstrap admin ${name} создан.`],
        [/^Manual invoice (.+) created\.$/, (number) => `Ручной инвойс ${number} создан.`],
        [/^Invoice (.+) metadata updated\.$/, (number) => `Метаданные инвойса ${number} обновлены.`],
        [/^Invoice (.+) assessment updated\.$/, (number) => `Оценка инвойса ${number} обновлена.`],
        [/^Warehub sync completed for account (.+)\.$/, (account) => `Синхронизация Warehub завершена для аккаунта ${account}.`],
        [/^File (.+) uploaded\.$/, (file) => `Файл ${file} загружен.`],
      ]
    : [
        [/^User (.+) signed in\.$/, (name) => `Benutzer ${name} hat sich angemeldet.`],
        [/^Refresh token rotated for (.+)\.$/, (name) => `Refresh-Token für ${name} wurde rotiert.`],
        [/^Session signed out\.$/, () => "Sitzung wurde beendet."],
        [/^User (.+) created\.$/, (name) => `Benutzer ${name} wurde erstellt.`],
        [/^User (.+) updated\.$/, (name) => `Benutzer ${name} wurde aktualisiert.`],
        [/^Bootstrap admin (.+) created\.$/, (name) => `Bootstrap-Admin ${name} wurde erstellt.`],
        [/^Manual invoice (.+) created\.$/, (number) => `Manuelle Rechnung ${number} wurde erstellt.`],
        [/^Invoice (.+) metadata updated\.$/, (number) => `Metadaten der Rechnung ${number} wurden aktualisiert.`],
        [/^Invoice (.+) assessment updated\.$/, (number) => `Bewertung der Rechnung ${number} wurde aktualisiert.`],
        [/^Warehub sync completed for account (.+)\.$/, (account) => `Warehub-Synchronisierung für Konto ${account} abgeschlossen.`],
        [/^File (.+) uploaded\.$/, (file) => `Datei ${file} wurde hochgeladen.`],
      ];

  for (const [pattern, formatter] of patterns) {
    const match = summary.match(pattern);
    if (match) {
      return formatter(...match.slice(1));
    }
  }

  return summary;
}
