import 'package:flutter/material.dart';

enum AppLocale { en, ru, de }

extension AppLocaleX on AppLocale {
  String get code => switch (this) {
    AppLocale.en => 'en',
    AppLocale.ru => 'ru',
    AppLocale.de => 'de',
  };

  Locale get locale => Locale(code);

  static AppLocale fromCode(String? code) {
    switch (code?.toLowerCase()) {
      case 'ru':
        return AppLocale.ru;
      case 'de':
        return AppLocale.de;
      default:
        return AppLocale.en;
    }
  }

  static AppLocale detectFromPlatform() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return fromCode(code);
  }
}

const supportedAppLocales = <AppLocale>[
  AppLocale.en,
  AppLocale.ru,
  AppLocale.de,
];

const supportedMaterialLocales = <Locale>[
  Locale('en'),
  Locale('ru'),
  Locale('de'),
];

class AppCopy {
  const AppCopy(this.locale);

  final AppLocale locale;

  static const _localeLabels = <AppLocale, String>{
    AppLocale.en: 'English',
    AppLocale.ru: 'Русский',
    AppLocale.de: 'Deutsch',
  };

  String localeLabel(AppLocale value) => _localeLabels[value]!;

  String get language => switch (locale) {
    AppLocale.en => 'Language',
    AppLocale.ru => 'Язык',
    AppLocale.de => 'Sprache',
  };

  String get theme => switch (locale) {
    AppLocale.en => 'Theme',
    AppLocale.ru => 'Тема',
    AppLocale.de => 'Design',
  };

  String get light => switch (locale) {
    AppLocale.en => 'Light',
    AppLocale.ru => 'Светлая',
    AppLocale.de => 'Hell',
  };

  String get dark => switch (locale) {
    AppLocale.en => 'Dark',
    AppLocale.ru => 'Тёмная',
    AppLocale.de => 'Dunkel',
  };

  String get checkingSession => switch (locale) {
    AppLocale.en => 'Checking session...',
    AppLocale.ru => 'Проверка сессии...',
    AppLocale.de => 'Sitzung wird geprüft...',
  };

  String get restoringSession => switch (locale) {
    AppLocale.en => 'Restoring secure mobile session...',
    AppLocale.ru => 'Восстанавливаем защищённую мобильную сессию...',
    AppLocale.de => 'Geschützte mobile Sitzung wird wiederhergestellt...',
  };

  String get workspace => switch (locale) {
    AppLocale.en => 'Workspace',
    AppLocale.ru => 'Рабочее пространство',
    AppLocale.de => 'Arbeitsbereich',
  };

  String get authEyebrow => switch (locale) {
    AppLocale.en => 'Woodguard / Auth',
    AppLocale.ru => 'Woodguard / Вход',
    AppLocale.de => 'Woodguard / Anmeldung',
  };

  String get indexEyebrow => switch (locale) {
    AppLocale.en => 'Woodguard / Index',
    AppLocale.ru => 'Woodguard / Индекс',
    AppLocale.de => 'Woodguard / Index',
  };

  String get authTitle => switch (locale) {
    AppLocale.en => 'Sign in to manage invoice dossiers and risk reviews.',
    AppLocale.ru =>
      'Войдите, чтобы управлять досье по инвойсам и проверкой рисков.',
    AppLocale.de =>
      'Melden Sie sich an, um Rechnungsdossiers und Risikoprüfungen zu verwalten.',
  };

  String get authDescription => switch (locale) {
    AppLocale.en =>
      'Use the same FastAPI backend as the web workspace. Session tokens are stored securely on-device.',
    AppLocale.ru =>
      'Мобильный клиент работает с тем же FastAPI backend, что и веб. Токены сессии хранятся на устройстве безопасно.',
    AppLocale.de =>
      'Der mobile Client nutzt dasselbe FastAPI-Backend wie das Web-Workspace. Sitzungstoken werden sicher auf dem Gerät gespeichert.',
  };

  String get defaultAdminNote => switch (locale) {
    AppLocale.en => 'Local default admin for testing: admin / woodguard123.',
    AppLocale.ru =>
      'Локальный администратор по умолчанию для тестов: admin / woodguard123.',
    AppLocale.de => 'Lokaler Standard-Admin für Tests: admin / woodguard123.',
  };

  String get usernameOrEmail => switch (locale) {
    AppLocale.en => 'Username or Email',
    AppLocale.ru => 'Логин или Email',
    AppLocale.de => 'Benutzername oder E-Mail',
  };

  String get password => switch (locale) {
    AppLocale.en => 'Password',
    AppLocale.ru => 'Пароль',
    AppLocale.de => 'Passwort',
  };

  String get signIn => switch (locale) {
    AppLocale.en => 'Sign In',
    AppLocale.ru => 'Войти',
    AppLocale.de => 'Anmelden',
  };

  String get signingIn => switch (locale) {
    AppLocale.en => 'Signing in...',
    AppLocale.ru => 'Выполняем вход...',
    AppLocale.de => 'Anmeldung läuft...',
  };

  String get signOut => switch (locale) {
    AppLocale.en => 'Sign Out',
    AppLocale.ru => 'Выйти',
    AppLocale.de => 'Abmelden',
  };

  String get signedOut => switch (locale) {
    AppLocale.en => 'Signed out.',
    AppLocale.ru => 'Вы вышли из системы.',
    AppLocale.de => 'Abgemeldet.',
  };

  String signedInAs(String username) => switch (locale) {
    AppLocale.en => 'Signed in as $username.',
    AppLocale.ru => 'Вы вошли как $username.',
    AppLocale.de => 'Angemeldet als $username.',
  };

  String get signInFailed => switch (locale) {
    AppLocale.en => 'Sign-in failed.',
    AppLocale.ru => 'Не удалось войти.',
    AppLocale.de => 'Anmeldung fehlgeschlagen.',
  };

  String get apiBaseUrl => switch (locale) {
    AppLocale.en => 'API Base URL',
    AppLocale.ru => 'Базовый URL API',
    AppLocale.de => 'API-Basis-URL',
  };

  String get apiHint => 'http://192.168.x.x:8000/api/v1';

  String get androidHint => switch (locale) {
    AppLocale.en => 'Android emulator: http://10.0.2.2:8000/api/v1',
    AppLocale.ru => 'Android-эмулятор: http://10.0.2.2:8000/api/v1',
    AppLocale.de => 'Android-Emulator: http://10.0.2.2:8000/api/v1',
  };

  String get iosHint => switch (locale) {
    AppLocale.en => 'iOS simulator: http://127.0.0.1:8000/api/v1',
    AppLocale.ru => 'iOS-симулятор: http://127.0.0.1:8000/api/v1',
    AppLocale.de => 'iOS-Simulator: http://127.0.0.1:8000/api/v1',
  };

  String get apiConnectivityNote => switch (locale) {
    AppLocale.en =>
      'Native mobile requests bypass browser CORS and talk directly to the same backend as the web app.',
    AppLocale.ru =>
      'Нативный мобильный клиент не зависит от browser CORS и обращается прямо к тому же backend, что и веб.',
    AppLocale.de =>
      'Der native Mobile-Client ist nicht von Browser-CORS abhängig und spricht direkt mit demselben Backend wie die Web-App.',
  };

  String get saveApiUrl => switch (locale) {
    AppLocale.en => 'Save API URL',
    AppLocale.ru => 'Сохранить URL API',
    AppLocale.de => 'API-URL speichern',
  };

  String get apiBaseUrlSaved => switch (locale) {
    AppLocale.en =>
      'API base URL saved. If the backend host changed, sign in again if needed.',
    AppLocale.ru =>
      'Базовый URL API сохранён. Если вы сменили адрес backend, при необходимости войдите заново.',
    AppLocale.de =>
      'API-Basis-URL gespeichert. Wenn sich der Backend-Host geändert hat, melden Sie sich bei Bedarf erneut an.',
  };

  static const _roleLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'admin': 'Admin',
      'analyst': 'Analyst',
      'reviewer': 'Reviewer',
      'viewer': 'Viewer',
    },
    AppLocale.ru: {
      'admin': 'Администратор',
      'analyst': 'Аналитик',
      'reviewer': 'Ревьюер',
      'viewer': 'Наблюдатель',
    },
    AppLocale.de: {
      'admin': 'Admin',
      'analyst': 'Analyst',
      'reviewer': 'Prüfer',
      'viewer': 'Betrachter',
    },
  };

  static const _riskLevelLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {'low': 'Low', 'medium': 'Medium', 'high': 'High'},
    AppLocale.ru: {'low': 'Низкий', 'medium': 'Средний', 'high': 'Высокий'},
    AppLocale.de: {'low': 'Niedrig', 'medium': 'Mittel', 'high': 'Hoch'},
  };

  static const _invoiceStatusLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'pending': 'Pending',
      'partial': 'Partial',
      'paid': 'Paid',
      'cancelled': 'Cancelled',
      'draft': 'Draft',
      'unknown': 'Unknown',
    },
    AppLocale.ru: {
      'pending': 'В ожидании',
      'partial': 'Частично',
      'paid': 'Оплачен',
      'cancelled': 'Отменён',
      'draft': 'Черновик',
      'unknown': 'Неизвестно',
    },
    AppLocale.de: {
      'pending': 'Ausstehend',
      'partial': 'Teilweise',
      'paid': 'Bezahlt',
      'cancelled': 'Storniert',
      'draft': 'Entwurf',
      'unknown': 'Unbekannt',
    },
  };

  static const _complianceLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {'yes': 'Yes', 'no': 'No', 'unknown': 'Unknown'},
    AppLocale.ru: {'yes': 'Да', 'no': 'Нет', 'unknown': 'Неизвестно'},
    AppLocale.de: {'yes': 'Ja', 'no': 'Nein', 'unknown': 'Unbekannt'},
  };

  static const _documentStatusLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'missing': 'Missing',
      'uploaded': 'Uploaded',
      'verified': 'Verified',
    },
    AppLocale.ru: {
      'missing': 'Нет',
      'uploaded': 'Загружено',
      'verified': 'Проверено',
    },
    AppLocale.de: {
      'missing': 'Fehlt',
      'uploaded': 'Hochgeladen',
      'verified': 'Verifiziert',
    },
  };

  static const _evidenceSectionLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'certificate': 'Certificate',
      'location_pictures': 'Location Pictures',
      'notice': 'Notice',
      'transport_papers': 'Transport Papers',
      'geolocation_screenshot': 'Geolocation Screenshot',
      'others': 'Other Evidence',
    },
    AppLocale.ru: {
      'certificate': 'Сертификат',
      'location_pictures': 'Фото локации',
      'notice': 'Уведомление',
      'transport_papers': 'Транспортные документы',
      'geolocation_screenshot': 'Скриншот геолокации',
      'others': 'Прочие доказательства',
    },
    AppLocale.de: {
      'certificate': 'Zertifikat',
      'location_pictures': 'Standortfotos',
      'notice': 'Hinweis',
      'transport_papers': 'Transportdokumente',
      'geolocation_screenshot': 'Geolokations-Screenshot',
      'others': 'Weitere Nachweise',
    },
  };

  static const _woodSpeciesLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'oak': 'Oak',
      'beech': 'Beech',
      'pine': 'Pine',
      'spruce': 'Spruce',
      'ash': 'Ash',
      'maple': 'Maple',
      'birch': 'Birch',
      'walnut': 'Walnut',
      'cherry': 'Cherry',
      'mahogany': 'Mahogany',
      'teak': 'Teak',
    },
    AppLocale.ru: {
      'oak': 'Дуб',
      'beech': 'Бук',
      'pine': 'Сосна',
      'spruce': 'Ель',
      'ash': 'Ясень',
      'maple': 'Клён',
      'birch': 'Берёза',
      'walnut': 'Орех',
      'cherry': 'Вишня',
      'mahogany': 'Махагони',
      'teak': 'Тик',
    },
    AppLocale.de: {
      'oak': 'Eiche',
      'beech': 'Buche',
      'pine': 'Kiefer',
      'spruce': 'Fichte',
      'ash': 'Esche',
      'maple': 'Ahorn',
      'birch': 'Birke',
      'walnut': 'Walnuss',
      'cherry': 'Kirsche',
      'mahogany': 'Mahagoni',
      'teak': 'Teak',
    },
  };

  static const _materialTypeLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'solid_wood': 'Solid Wood',
      'mdf': 'MDF',
      'hdf': 'HDF',
      'particle_board': 'Particle Board',
      'plywood': 'Plywood',
      'veneer': 'Veneer',
      'other': 'Other',
    },
    AppLocale.ru: {
      'solid_wood': 'Массив дерева',
      'mdf': 'MDF',
      'hdf': 'HDF',
      'particle_board': 'ДСП',
      'plywood': 'Фанера',
      'veneer': 'Шпон',
      'other': 'Другое',
    },
    AppLocale.de: {
      'solid_wood': 'Massivholz',
      'mdf': 'MDF',
      'hdf': 'HDF',
      'particle_board': 'Spanplatte',
      'plywood': 'Sperrholz',
      'veneer': 'Furnier',
      'other': 'Andere',
    },
  };

  static const _breakdownLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'certificate_document': 'Certificate',
      'certificate_memo': 'Certificate Memo',
      'location_pictures_document': 'Location Pictures',
      'location_pictures_memo': 'Location Memo',
      'notice_document': 'Notice',
      'notice_memo': 'Notice Memo',
      'wood_specification': 'Wood Specification',
      'country_of_origin': 'Country of Origin',
      'quantity': 'Quantity',
      'slice_count': 'Slices',
      'area_square_meters': 'Area (m²)',
      'delivery_date': 'Delivery Date',
      'child_labor': 'Child Labor',
      'human_rights': 'Human Rights',
      'geolocation_screenshot': 'Geolocation Screenshot',
      'geolocation_data': 'Geolocation Data',
      'personal_risk_level': 'Personal Risk',
      'risk_reason': 'Risk Rationale',
      'others': 'Other Evidence',
      'transport_papers_document': 'Transport Papers',
      'transport_papers_memo': 'Transport Memo',
      'invoice.geolocation.autofill': 'Geolocation Auto-Fill',
    },
    AppLocale.ru: {
      'certificate_document': 'Сертификат',
      'certificate_memo': 'Комментарий к сертификату',
      'location_pictures_document': 'Фото локации',
      'location_pictures_memo': 'Комментарий по локации',
      'notice_document': 'Уведомление',
      'notice_memo': 'Комментарий к уведомлению',
      'wood_specification': 'Спецификация древесины',
      'country_of_origin': 'Страна происхождения',
      'quantity': 'Количество',
      'slice_count': 'Слэбы',
      'area_square_meters': 'Площадь (м²)',
      'delivery_date': 'Дата поставки',
      'child_labor': 'Ответ по детскому труду',
      'human_rights': 'Ответ по правам человека',
      'geolocation_screenshot': 'Скриншот геолокации',
      'geolocation_data': 'Данные геолокации',
      'personal_risk_level': 'Личная оценка риска',
      'risk_reason': 'Обоснование риска',
      'others': 'Прочие доказательства',
      'transport_papers_document': 'Транспортные документы',
      'transport_papers_memo': 'Комментарий по транспорту',
      'invoice.geolocation.autofill': 'Автозаполнение геолокации',
    },
    AppLocale.de: {
      'certificate_document': 'Zertifikat',
      'certificate_memo': 'Zertifikatsnotiz',
      'location_pictures_document': 'Standortfotos',
      'location_pictures_memo': 'Standortnotiz',
      'notice_document': 'Hinweis',
      'notice_memo': 'Hinweisnotiz',
      'wood_specification': 'Holzspezifikation',
      'country_of_origin': 'Ursprungsland',
      'quantity': 'Menge',
      'slice_count': 'Platten',
      'area_square_meters': 'Fläche (m²)',
      'delivery_date': 'Lieferdatum',
      'child_labor': 'Antwort zu Kinderarbeit',
      'human_rights': 'Antwort zu Menschenrechten',
      'geolocation_screenshot': 'Geolokations-Screenshot',
      'geolocation_data': 'Geolokationsdaten',
      'personal_risk_level': 'Persönliche Risikobewertung',
      'risk_reason': 'Risikobegründung',
      'others': 'Weitere Nachweise',
      'transport_papers_document': 'Transportdokumente',
      'transport_papers_memo': 'Transportnotiz',
      'invoice.geolocation.autofill': 'Geolokation automatisch erkannt',
    },
  };

  static const _auditActionLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {
      'auth.login': 'Login',
      'auth.refresh': 'Refresh Token',
      'auth.logout': 'Logout',
      'user.create': 'User Created',
      'user.update': 'User Updated',
      'user.bootstrap_admin': 'Bootstrap Admin Created',
      'invoice.create': 'Invoice Created',
      'invoice.metadata.update': 'Metadata Updated',
      'invoice.assessment.update': 'Assessment Updated',
      'invoice.geolocation.autofill': 'Geolocation Auto-Fill',
      'invoice.sync.warehub': 'Warehub Sync',
      'upload.create': 'File Uploaded',
    },
    AppLocale.ru: {
      'auth.login': 'Вход',
      'auth.refresh': 'Обновление токена',
      'auth.logout': 'Выход',
      'user.create': 'Создание пользователя',
      'user.update': 'Обновление пользователя',
      'user.bootstrap_admin': 'Создание bootstrap admin',
      'invoice.create': 'Создание инвойса',
      'invoice.metadata.update': 'Обновление метаданных',
      'invoice.assessment.update': 'Обновление оценки',
      'invoice.geolocation.autofill': 'Автозаполнение геолокации',
      'invoice.sync.warehub': 'Синхронизация Warehub',
      'upload.create': 'Загрузка файла',
    },
    AppLocale.de: {
      'auth.login': 'Anmeldung',
      'auth.refresh': 'Token-Aktualisierung',
      'auth.logout': 'Abmeldung',
      'user.create': 'Benutzer angelegt',
      'user.update': 'Benutzer aktualisiert',
      'user.bootstrap_admin': 'Bootstrap-Admin angelegt',
      'invoice.create': 'Rechnung angelegt',
      'invoice.metadata.update': 'Metadaten aktualisiert',
      'invoice.assessment.update': 'Bewertung aktualisiert',
      'invoice.geolocation.autofill': 'Geolokation automatisch erkannt',
      'invoice.sync.warehub': 'Warehub-Synchronisierung',
      'upload.create': 'Datei hochgeladen',
    },
  };

  static const _storageLabels = <AppLocale, Map<String, String>>{
    AppLocale.en: {'local': 'local storage', 's3': 'S3 storage'},
    AppLocale.ru: {'local': 'локальное хранилище', 's3': 'S3-хранилище'},
    AppLocale.de: {'local': 'lokaler Speicher', 's3': 'S3-Speicher'},
  };

  String get overviewTab => switch (locale) {
    AppLocale.en => 'Overview',
    AppLocale.ru => 'Обзор',
    AppLocale.de => 'Übersicht',
  };

  String get evidenceTab => switch (locale) {
    AppLocale.en => 'Evidence',
    AppLocale.ru => 'Доказательства',
    AppLocale.de => 'Nachweise',
  };

  String get analyticsTab => switch (locale) {
    AppLocale.en => 'Analytics',
    AppLocale.ru => 'Аналитика',
    AppLocale.de => 'Analytik',
  };

  String get dashboardTitle => switch (locale) {
    AppLocale.en => 'Field Overview',
    AppLocale.ru => 'Общий обзор',
    AppLocale.de => 'Gesamtübersicht',
  };

  String dashboardSubtitle(String? username) => switch (locale) {
    AppLocale.en => username == null ? workspace : 'Signed in as $username',
    AppLocale.ru => username == null ? workspace : 'Пользователь: $username',
    AppLocale.de => username == null ? workspace : 'Angemeldet als $username',
  };

  String get dashboardLoading => switch (locale) {
    AppLocale.en => 'Loading dashboard metrics...',
    AppLocale.ru => 'Загружаем метрики дашборда...',
    AppLocale.de => 'Dashboard-Metriken werden geladen...',
  };

  String get dashboardUnavailable => switch (locale) {
    AppLocale.en => 'Dashboard unavailable',
    AppLocale.ru => 'Дашборд недоступен',
    AppLocale.de => 'Dashboard nicht verfügbar',
  };

  String get dashboardFallback => switch (locale) {
    AppLocale.en => 'Check API connectivity and sign in again if needed.',
    AppLocale.ru =>
      'Проверьте доступность API и при необходимости войдите заново.',
    AppLocale.de =>
      'Prüfen Sie die API-Verbindung und melden Sie sich bei Bedarf erneut an.',
  };

  String get compliancePulseTitle => switch (locale) {
    AppLocale.en => 'Live compliance pulse',
    AppLocale.ru => 'Живой пульс комплаенса',
    AppLocale.de => 'Live-Compliance-Puls',
  };

  String get compliancePulseBody => switch (locale) {
    AppLocale.en =>
      'Track exposure, risk spikes and supplier pressure in one mobile command view.',
    AppLocale.ru =>
      'Следите за открытой суммой, всплесками риска и давлением со стороны поставщиков в одном мобильном экране.',
    AppLocale.de =>
      'Verfolgen Sie Exposure, Risikospitzen und Lieferantendruck in einer mobilen Leitansicht.',
  };

  String get operationalPulse => switch (locale) {
    AppLocale.en => 'Operational Pulse',
    AppLocale.ru => 'Операционный пульс',
    AppLocale.de => 'Operativer Puls',
  };

  String paidOpenLabel(int paid, int open) => switch (locale) {
    AppLocale.en => 'Paid: $paid | Open: $open',
    AppLocale.ru => 'Оплачено: $paid | Открыто: $open',
    AppLocale.de => 'Bezahlt: $paid | Offen: $open',
  };

  String nonEuSuppliersLabel(int count) => switch (locale) {
    AppLocale.en => 'Non-EU suppliers: $count',
    AppLocale.ru => 'Поставщики вне ЕС: $count',
    AppLocale.de => 'Lieferanten außerhalb der EU: $count',
  };

  String lastSyncLabel(String value) => switch (locale) {
    AppLocale.en => 'Last sync: $value',
    AppLocale.ru => 'Последняя синхронизация: $value',
    AppLocale.de => 'Letzte Synchronisierung: $value',
  };

  String get suppliersTitle => switch (locale) {
    AppLocale.en => 'Supplier Pressure',
    AppLocale.ru => 'Давление по поставщикам',
    AppLocale.de => 'Lieferantendruck',
  };

  String supplierCount(int count) => switch (locale) {
    AppLocale.en => '$count suppliers',
    AppLocale.ru => '$count поставщиков',
    AppLocale.de => '$count Lieferanten',
  };

  String get noSuppliersYet => switch (locale) {
    AppLocale.en => 'No suppliers yet',
    AppLocale.ru => 'Поставщиков пока нет',
    AppLocale.de => 'Noch keine Lieferanten',
  };

  String get noSuppliersHint => switch (locale) {
    AppLocale.en => 'Sync Warehub or create invoices from the workspace first.',
    AppLocale.ru =>
      'Сначала синхронизируйте Warehub или создайте инвойсы вручную.',
    AppLocale.de =>
      'Synchronisieren Sie zuerst Warehub oder erstellen Sie manuelle Rechnungen.',
  };

  String get countryNotSet => switch (locale) {
    AppLocale.en => 'Country not set',
    AppLocale.ru => 'Страна не указана',
    AppLocale.de => 'Land nicht gesetzt',
  };

  String supplierOpenSummary(int invoiceCount, String exposure) =>
      switch (locale) {
        AppLocale.en => '$invoiceCount invoices | $exposure open',
        AppLocale.ru => '$invoiceCount инвойсов | $exposure открыто',
        AppLocale.de => '$invoiceCount Rechnungen | $exposure offen',
      };

  String supplierHighRiskCount(int count) => switch (locale) {
    AppLocale.en => '$count high',
    AppLocale.ru => '$count высокий',
    AppLocale.de => '$count hoch',
  };

  String get invoices => switch (locale) {
    AppLocale.en => 'Invoices',
    AppLocale.ru => 'Инвойсы',
    AppLocale.de => 'Rechnungen',
  };

  String get account => switch (locale) {
    AppLocale.en => 'Account',
    AppLocale.ru => 'Аккаунт',
    AppLocale.de => 'Konto',
  };

  String get openExposure => switch (locale) {
    AppLocale.en => 'Open Exposure',
    AppLocale.ru => 'Открытая сумма',
    AppLocale.de => 'Offenes Exposure',
  };

  String get coverageAverage => switch (locale) {
    AppLocale.en => 'Coverage Avg',
    AppLocale.ru => 'Среднее покрытие',
    AppLocale.de => 'Deckungsgrad',
  };

  String get highRisk => switch (locale) {
    AppLocale.en => 'High Risk',
    AppLocale.ru => 'Высокий риск',
    AppLocale.de => 'Hohes Risiko',
  };

  String get recentInvoices => switch (locale) {
    AppLocale.en => 'Recent Invoices',
    AppLocale.ru => 'Последние инвойсы',
    AppLocale.de => 'Letzte Rechnungen',
  };

  String get notifications => switch (locale) {
    AppLocale.en => 'Notifications',
    AppLocale.ru => 'Уведомления',
    AppLocale.de => 'Benachrichtigungen',
  };

  String get recentInvoicesEmpty => switch (locale) {
    AppLocale.en => 'No invoices available in the current filter.',
    AppLocale.ru => 'В текущем фильтре нет инвойсов.',
    AppLocale.de => 'Keine Rechnungen im aktuellen Filter.',
  };

  String get latestActivity => switch (locale) {
    AppLocale.en => 'Latest Activity',
    AppLocale.ru => 'Последняя активность',
    AppLocale.de => 'Letzte Aktivität',
  };

  String get search => switch (locale) {
    AppLocale.en => 'Search',
    AppLocale.ru => 'Поиск',
    AppLocale.de => 'Suche',
  };

  String get searchPlaceholder => switch (locale) {
    AppLocale.en => 'Invoice / company / seller',
    AppLocale.ru => 'Инвойс / компания / продавец',
    AppLocale.de => 'Rechnung / Firma / Verkäufer',
  };

  String get status => switch (locale) {
    AppLocale.en => 'Status',
    AppLocale.ru => 'Статус',
    AppLocale.de => 'Status',
  };

  String get riskLevel => switch (locale) {
    AppLocale.en => 'Risk level',
    AppLocale.ru => 'Уровень риска',
    AppLocale.de => 'Risikostufe',
  };

  String get all => switch (locale) {
    AppLocale.en => 'All',
    AppLocale.ru => 'Все',
    AppLocale.de => 'Alle',
  };

  String get mobileDossiersTitle => switch (locale) {
    AppLocale.en => 'Mobile Dossiers',
    AppLocale.ru => 'Мобильные досье',
    AppLocale.de => 'Mobile Dossiers',
  };

  String get mobileDossiersSubtitle => switch (locale) {
    AppLocale.en =>
      'Search, filter, open and update invoice dossiers from the same backend as the web workspace.',
    AppLocale.ru =>
      'Ищите, фильтруйте, открывайте и обновляйте досье по инвойсам из того же backend, что и веб-кабинет.',
    AppLocale.de =>
      'Suchen, filtern, öffnen und aktualisieren Sie Rechnungsdossiers über dasselbe Backend wie das Web-Workspace.',
  };

  String dossiersVisible(int count) => switch (locale) {
    AppLocale.en =>
      '$count dossiers visible. Refine by status and risk, then open a record in one tap.',
    AppLocale.ru =>
      'Видно $count досье. Уточните статус и риск, затем откройте запись одним нажатием.',
    AppLocale.de =>
      '$count Dossiers sichtbar. Verfeinern Sie Status und Risiko und öffnen Sie einen Datensatz mit einem Tipp.',
  };

  String get loadingInvoiceQueue => switch (locale) {
    AppLocale.en => 'Loading invoice queue...',
    AppLocale.ru => 'Загружаем очередь инвойсов...',
    AppLocale.de => 'Rechnungswarteschlange wird geladen...',
  };

  String get noDossiersMatched => switch (locale) {
    AppLocale.en => 'No dossiers matched',
    AppLocale.ru => 'Досье не найдены',
    AppLocale.de => 'Keine Dossiers gefunden',
  };

  String get noDossiersHint => switch (locale) {
    AppLocale.en =>
      'Try a broader search or sync fresh invoice data from the account screen.',
    AppLocale.ru =>
      'Попробуйте более широкий поиск или синхронизируйте свежие данные инвойсов с экрана аккаунта.',
    AppLocale.de =>
      'Versuchen Sie eine breitere Suche oder synchronisieren Sie aktuelle Rechnungsdaten im Konto-Bereich.',
  };

  String get manualInvoice => switch (locale) {
    AppLocale.en => 'Manual Invoice',
    AppLocale.ru => 'Ручной инвойс',
    AppLocale.de => 'Manuelle Rechnung',
  };

  String get createManualInvoice => switch (locale) {
    AppLocale.en => 'Create Manual Invoice',
    AppLocale.ru => 'Создать инвойс вручную',
    AppLocale.de => 'Manuelle Rechnung erstellen',
  };

  String get manualInvoiceSubtitle => switch (locale) {
    AppLocale.en => 'Quick mobile fallback when Warehub data is not enough.',
    AppLocale.ru =>
      'Быстрый мобильный сценарий, когда данных из Warehub недостаточно.',
    AppLocale.de =>
      'Schneller mobiler Fallback, wenn Warehub-Daten nicht ausreichen.',
  };

  String get invoiceNumber => switch (locale) {
    AppLocale.en => 'Invoice Number',
    AppLocale.ru => 'Номер инвойса',
    AppLocale.de => 'Rechnungsnummer',
  };

  String get invoiceNumberRequired => switch (locale) {
    AppLocale.en => 'Invoice number is required.',
    AppLocale.ru => 'Номер инвойса обязателен.',
    AppLocale.de => 'Rechnungsnummer ist erforderlich.',
  };

  String get companyName => switch (locale) {
    AppLocale.en => 'Company Name',
    AppLocale.ru => 'Название компании',
    AppLocale.de => 'Firmenname',
  };

  String get country => switch (locale) {
    AppLocale.en => 'Country',
    AppLocale.ru => 'Страна',
    AppLocale.de => 'Land',
  };

  String get amount => switch (locale) {
    AppLocale.en => 'Amount',
    AppLocale.ru => 'Сумма',
    AppLocale.de => 'Betrag',
  };

  String get creatingInvoice => switch (locale) {
    AppLocale.en => 'Creating invoice...',
    AppLocale.ru => 'Создаём инвойс...',
    AppLocale.de => 'Rechnung wird erstellt...',
  };

  String get invoiceDossierSaved => switch (locale) {
    AppLocale.en => 'Invoice dossier saved.',
    AppLocale.ru => 'Досье по инвойсу сохранено.',
    AppLocale.de => 'Rechnungsdossier gespeichert.',
  };

  String get invoiceDossierSaveFailed => switch (locale) {
    AppLocale.en => 'Failed to save invoice dossier.',
    AppLocale.ru => 'Не удалось сохранить досье по инвойсу.',
    AppLocale.de => 'Rechnungsdossier konnte nicht gespeichert werden.',
  };

  String get geolocationAutofillHint => switch (locale) {
    AppLocale.en =>
      'Fill geolocation source, seller address, label or seller name first.',
    AppLocale.ru =>
      'Сначала заполните источник геолокации, адрес продавца, подпись локации или имя продавца.',
    AppLocale.de =>
      'Füllen Sie zuerst Geolokationsquelle, Verkäuferadresse, Standortlabel oder Verkäufernamen aus.',
  };

  String get geolocationRefreshed => switch (locale) {
    AppLocale.en => 'Geolocation fields refreshed from backend lookup.',
    AppLocale.ru => 'Поля геолокации обновлены по данным backend-поиска.',
    AppLocale.de =>
      'Geolokationsfelder wurden per Backend-Abfrage aktualisiert.',
  };

  String get locationPermissionDenied => switch (locale) {
    AppLocale.en => 'Location permission was denied.',
    AppLocale.ru => 'Доступ к геолокации отклонён.',
    AppLocale.de => 'Standortberechtigung wurde verweigert.',
  };

  String get currentCoordinatesLoaded => switch (locale) {
    AppLocale.en =>
      'Current coordinates loaded into the draft. Review and save.',
    AppLocale.ru =>
      'Текущие координаты подставлены в черновик. Проверьте и сохраните.',
    AppLocale.de =>
      'Aktuelle Koordinaten wurden in den Entwurf geladen. Prüfen und speichern.',
  };

  String get currentLocationLoaded => switch (locale) {
    AppLocale.en => 'Current location loaded into the draft. Review and save.',
    AppLocale.ru =>
      'Текущая локация подставлена в черновик. Проверьте и сохраните.',
    AppLocale.de =>
      'Aktueller Standort wurde in den Entwurf geladen. Prüfen und speichern.',
  };

  String evidenceUploaded(int count, String section) => switch (locale) {
    AppLocale.en => '$count file(s) uploaded for $section.',
    AppLocale.ru => 'Загружено файлов для раздела "$section": $count.',
    AppLocale.de => '$count Datei(en) für "$section" hochgeladen.',
  };

  String get loadingDossier => switch (locale) {
    AppLocale.en => 'Loading dossier...',
    AppLocale.ru => 'Загружаем досье...',
    AppLocale.de => 'Dossier wird geladen...',
  };

  String get invoiceUnavailable => switch (locale) {
    AppLocale.en => 'Invoice not available',
    AppLocale.ru => 'Инвойс недоступен',
    AppLocale.de => 'Rechnung nicht verfügbar',
  };

  String get invoiceUnavailableHint => switch (locale) {
    AppLocale.en =>
      'The invoice could not be loaded. Refresh the queue and try again.',
    AppLocale.ru =>
      'Не удалось загрузить инвойс. Обновите очередь и попробуйте снова.',
    AppLocale.de =>
      'Die Rechnung konnte nicht geladen werden. Aktualisieren Sie die Warteschlange und versuchen Sie es erneut.',
  };

  String get saveDossier => switch (locale) {
    AppLocale.en => 'Save Dossier',
    AppLocale.ru => 'Сохранить досье',
    AppLocale.de => 'Dossier speichern',
  };

  String get saving => switch (locale) {
    AppLocale.en => 'Saving...',
    AppLocale.ru => 'Сохранение...',
    AppLocale.de => 'Wird gespeichert...',
  };

  String get saveInvoiceDossier => switch (locale) {
    AppLocale.en => 'Save Invoice Dossier',
    AppLocale.ru => 'Сохранить досье по инвойсу',
    AppLocale.de => 'Rechnungsdossier speichern',
  };

  String get thisRoleReadOnly => switch (locale) {
    AppLocale.en =>
      'This role can inspect the dossier but cannot write changes.',
    AppLocale.ru =>
      'Эта роль может просматривать досье, но не может вносить изменения.',
    AppLocale.de =>
      'Diese Rolle kann das Dossier ansehen, aber keine Änderungen speichern.',
  };

  String get metadata => switch (locale) {
    AppLocale.en => 'Invoice Metadata',
    AppLocale.ru => 'Метаданные инвойса',
    AppLocale.de => 'Rechnungsmetadaten',
  };

  String get remainingAmount => switch (locale) {
    AppLocale.en => 'Remaining Amount',
    AppLocale.ru => 'Оставшаяся сумма',
    AppLocale.de => 'Restbetrag',
  };

  String get invoiceDate => switch (locale) {
    AppLocale.en => 'Invoice Date',
    AppLocale.ru => 'Дата инвойса',
    AppLocale.de => 'Rechnungsdatum',
  };

  String get dueDate => switch (locale) {
    AppLocale.en => 'Due Date',
    AppLocale.ru => 'Срок оплаты',
    AppLocale.de => 'Fälligkeitsdatum',
  };

  String get productionDate => switch (locale) {
    AppLocale.en => 'Production Date',
    AppLocale.ru => 'Дата производства',
    AppLocale.de => 'Produktionsdatum',
  };

  String get importDate => switch (locale) {
    AppLocale.en => 'Import Date',
    AppLocale.ru => 'Дата импорта',
    AppLocale.de => 'Importdatum',
  };

  String get internalNotes => switch (locale) {
    AppLocale.en => 'Internal Notes',
    AppLocale.ru => 'Внутренние заметки',
    AppLocale.de => 'Interne Notizen',
  };

  String get sellerCard => switch (locale) {
    AppLocale.en => 'Seller Card',
    AppLocale.ru => 'Карточка продавца',
    AppLocale.de => 'Verkäuferkarte',
  };

  String get sellerName => switch (locale) {
    AppLocale.en => 'Seller Name',
    AppLocale.ru => 'Название продавца',
    AppLocale.de => 'Verkäufername',
  };

  String get address => switch (locale) {
    AppLocale.en => 'Address',
    AppLocale.ru => 'Адрес',
    AppLocale.de => 'Adresse',
  };

  String get phone => switch (locale) {
    AppLocale.en => 'Phone',
    AppLocale.ru => 'Телефон',
    AppLocale.de => 'Telefon',
  };

  String get email => switch (locale) {
    AppLocale.en => 'Email',
    AppLocale.ru => 'Email',
    AppLocale.de => 'E-Mail',
  };

  String get website => switch (locale) {
    AppLocale.en => 'Website',
    AppLocale.ru => 'Сайт',
    AppLocale.de => 'Webseite',
  };

  String get contactPerson => switch (locale) {
    AppLocale.en => 'Contact Person',
    AppLocale.ru => 'Контактное лицо',
    AppLocale.de => 'Kontaktperson',
  };

  String get geolocationLabel => switch (locale) {
    AppLocale.en => 'Geolocation Label',
    AppLocale.ru => 'Подпись геолокации',
    AppLocale.de => 'Geolokationslabel',
  };

  String get latitude => switch (locale) {
    AppLocale.en => 'Latitude',
    AppLocale.ru => 'Широта',
    AppLocale.de => 'Breitengrad',
  };

  String get longitude => switch (locale) {
    AppLocale.en => 'Longitude',
    AppLocale.ru => 'Долгота',
    AppLocale.de => 'Längengrad',
  };

  String get geolocation => switch (locale) {
    AppLocale.en => 'Geolocation',
    AppLocale.ru => 'Геолокация',
    AppLocale.de => 'Geolokation',
  };

  String get geolocationSource => switch (locale) {
    AppLocale.en => 'Geolocation Source',
    AppLocale.ru => 'Источник геолокации',
    AppLocale.de => 'Geolokationsquelle',
  };

  String get sellerLatitude => switch (locale) {
    AppLocale.en => 'Seller Latitude',
    AppLocale.ru => 'Широта продавца',
    AppLocale.de => 'Breitengrad Verkäufer',
  };

  String get sellerLongitude => switch (locale) {
    AppLocale.en => 'Seller Longitude',
    AppLocale.ru => 'Долгота продавца',
    AppLocale.de => 'Längengrad Verkäufer',
  };

  String get assessmentLatitude => switch (locale) {
    AppLocale.en => 'Assessment Latitude',
    AppLocale.ru => 'Широта оценки',
    AppLocale.de => 'Breitengrad Bewertung',
  };

  String get assessmentLongitude => switch (locale) {
    AppLocale.en => 'Assessment Longitude',
    AppLocale.ru => 'Долгота оценки',
    AppLocale.de => 'Längengrad Bewertung',
  };

  String get useCurrentLocation => switch (locale) {
    AppLocale.en => 'Use Current Location',
    AppLocale.ru => 'Использовать текущую локацию',
    AppLocale.de => 'Aktuellen Standort verwenden',
  };

  String get readingDeviceLocation => switch (locale) {
    AppLocale.en => 'Reading device location...',
    AppLocale.ru => 'Считываем геолокацию устройства...',
    AppLocale.de => 'Gerätestandort wird gelesen...',
  };

  String get autoDetectFromFields => switch (locale) {
    AppLocale.en => 'Auto Detect From Fields',
    AppLocale.ru => 'Определить по полям',
    AppLocale.de => 'Aus Feldern automatisch erkennen',
  };

  String get resolvingLocation => switch (locale) {
    AppLocale.en => 'Resolving location...',
    AppLocale.ru => 'Определяем локацию...',
    AppLocale.de => 'Standort wird bestimmt...',
  };

  String get openMap => switch (locale) {
    AppLocale.en => 'Open Map',
    AppLocale.ru => 'Открыть карту',
    AppLocale.de => 'Karte öffnen',
  };

  String get geoSnapshot => switch (locale) {
    AppLocale.en => 'Geo Snapshot',
    AppLocale.ru => 'Гео-снимок',
    AppLocale.de => 'Geo-Snapshot',
  };

  String get coordinates => switch (locale) {
    AppLocale.en => 'Coordinates',
    AppLocale.ru => 'Координаты',
    AppLocale.de => 'Koordinaten',
  };

  String get mapPreview => switch (locale) {
    AppLocale.en => 'Map Preview',
    AppLocale.ru => 'Предпросмотр карты',
    AppLocale.de => 'Kartenvorschau',
  };

  String get unset => switch (locale) {
    AppLocale.en => 'Unset',
    AppLocale.ru => 'Не задано',
    AppLocale.de => 'Nicht gesetzt',
  };

  String get evidenceSections => switch (locale) {
    AppLocale.en => 'Evidence Sections',
    AppLocale.ru => 'Разделы доказательств',
    AppLocale.de => 'Nachweisabschnitte',
  };

  String get uploadEvidence => switch (locale) {
    AppLocale.en => 'Upload Evidence',
    AppLocale.ru => 'Загрузить файл',
    AppLocale.de => 'Nachweis hochladen',
  };

  String get uploading => switch (locale) {
    AppLocale.en => 'Uploading...',
    AppLocale.ru => 'Загрузка...',
    AppLocale.de => 'Wird hochgeladen...',
  };

  String get memo => switch (locale) {
    AppLocale.en => 'Memo',
    AppLocale.ru => 'Комментарий',
    AppLocale.de => 'Notiz',
  };

  String get currentFiles => switch (locale) {
    AppLocale.en => 'Current Files',
    AppLocale.ru => 'Текущие файлы',
    AppLocale.de => 'Aktuelle Dateien',
  };

  String get woodSpecification => switch (locale) {
    AppLocale.en => 'Wood Specification',
    AppLocale.ru => 'Спецификация древесины',
    AppLocale.de => 'Holzspezifikation',
  };

  String get woodSpecies => switch (locale) {
    AppLocale.en => 'Wood Species',
    AppLocale.ru => 'Породы древесины',
    AppLocale.de => 'Holzarten',
  };

  String get materialTypes => switch (locale) {
    AppLocale.en => 'Material Types',
    AppLocale.ru => 'Типы материалов',
    AppLocale.de => 'Materialarten',
  };

  String get woodSpecificationMemo => switch (locale) {
    AppLocale.en => 'Wood Specification Memo',
    AppLocale.ru => 'Комментарий к спецификации древесины',
    AppLocale.de => 'Notiz zur Holzspezifikation',
  };

  String get countryOfOrigin => switch (locale) {
    AppLocale.en => 'Country of Origin',
    AppLocale.ru => 'Страна происхождения',
    AppLocale.de => 'Ursprungsland',
  };

  String get deliveryDate => switch (locale) {
    AppLocale.en => 'Delivery Date',
    AppLocale.ru => 'Дата поставки',
    AppLocale.de => 'Lieferdatum',
  };

  String get quantity => switch (locale) {
    AppLocale.en => 'Quantity',
    AppLocale.ru => 'Количество',
    AppLocale.de => 'Menge',
  };

  String get unit => switch (locale) {
    AppLocale.en => 'Unit',
    AppLocale.ru => 'Единица',
    AppLocale.de => 'Einheit',
  };

  String get sliceCount => switch (locale) {
    AppLocale.en => 'Slices',
    AppLocale.ru => 'Слэбы',
    AppLocale.de => 'Platten',
  };

  String get areaSquareMeters => switch (locale) {
    AppLocale.en => 'Area (m²)',
    AppLocale.ru => 'Площадь (м²)',
    AppLocale.de => 'Fläche (m²)',
  };

  String get selectCountry => switch (locale) {
    AppLocale.en => 'Select country',
    AppLocale.ru => 'Выберите страну',
    AppLocale.de => 'Land auswählen',
  };

  String get riskInputs => switch (locale) {
    AppLocale.en => 'Risk Inputs',
    AppLocale.ru => 'Факторы риска',
    AppLocale.de => 'Risikoeingaben',
  };

  String get childLabor => switch (locale) {
    AppLocale.en => 'Child Labor',
    AppLocale.ru => 'Детский труд',
    AppLocale.de => 'Kinderarbeit',
  };

  String get humanRights => switch (locale) {
    AppLocale.en => 'Human Rights',
    AppLocale.ru => 'Права человека',
    AppLocale.de => 'Menschenrechte',
  };

  String get personalRiskAssessment => switch (locale) {
    AppLocale.en => 'Personal Risk Assessment',
    AppLocale.ru => 'Личная оценка риска',
    AppLocale.de => 'Persönliche Risikobewertung',
  };

  String get why => switch (locale) {
    AppLocale.en => 'Why?',
    AppLocale.ru => 'Почему?',
    AppLocale.de => 'Warum?',
  };

  String get coverage => switch (locale) {
    AppLocale.en => 'Coverage',
    AppLocale.ru => 'Покрытие',
    AppLocale.de => 'Deckung',
  };

  String get penalties => switch (locale) {
    AppLocale.en => 'Penalties',
    AppLocale.ru => 'Штрафы',
    AppLocale.de => 'Strafpunkte',
  };

  String get riskBlockers => switch (locale) {
    AppLocale.en => 'Risk Blockers',
    AppLocale.ru => 'Блокеры риска',
    AppLocale.de => 'Risikoblocker',
  };

  String get riskScore => switch (locale) {
    AppLocale.en => 'Risk Score',
    AppLocale.ru => 'Оценка риска',
    AppLocale.de => 'Risikoscore',
  };

  String get pendingEvidence => switch (locale) {
    AppLocale.en => 'Pending Evidence',
    AppLocale.ru => 'Ожидающие доказательства',
    AppLocale.de => 'Ausstehende Nachweise',
  };

  String get uploadedEvidence => switch (locale) {
    AppLocale.en => 'Uploaded Evidence',
    AppLocale.ru => 'Загруженные файлы',
    AppLocale.de => 'Hochgeladene Nachweise',
  };

  String get verifiedSections => switch (locale) {
    AppLocale.en => 'Verified Sections',
    AppLocale.ru => 'Проверенные разделы',
    AppLocale.de => 'Verifizierte Abschnitte',
  };

  String get auditTrail => switch (locale) {
    AppLocale.en => 'Audit Trail',
    AppLocale.ru => 'История аудита',
    AppLocale.de => 'Audit-Trail',
  };

  String get noAuditActivity => switch (locale) {
    AppLocale.en => 'No audit activity recorded for this invoice yet.',
    AppLocale.ru => 'Для этого инвойса ещё нет записей в аудите.',
    AppLocale.de => 'Für diese Rechnung gibt es noch keine Audit-Einträge.',
  };

  String get noSummaryProvided => switch (locale) {
    AppLocale.en => 'No summary provided.',
    AppLocale.ru => 'Сводка не указана.',
    AppLocale.de => 'Keine Zusammenfassung vorhanden.',
  };

  String get actor => switch (locale) {
    AppLocale.en => 'Actor',
    AppLocale.ru => 'Исполнитель',
    AppLocale.de => 'Akteur',
  };

  String get systemActor => switch (locale) {
    AppLocale.en => 'system',
    AppLocale.ru => 'система',
    AppLocale.de => 'System',
  };

  String get breakdown => switch (locale) {
    AppLocale.en => 'Breakdown',
    AppLocale.ru => 'Разбивка',
    AppLocale.de => 'Aufschlüsselung',
  };

  String get blockers => switch (locale) {
    AppLocale.en => 'Blockers',
    AppLocale.ru => 'Блокеры',
    AppLocale.de => 'Blocker',
  };

  String get noInvoicesYet => switch (locale) {
    AppLocale.en =>
      'No invoices yet. Sync Warehub or create the first manual index to start.',
    AppLocale.ru =>
      'Инвойсов пока нет. Синхронизируйте Warehub или создайте первый ручной инвойс.',
    AppLocale.de =>
      'Noch keine Rechnungen. Synchronisieren Sie Warehub oder erstellen Sie die erste manuelle Rechnung.',
  };

  String get unassignedSupplier => switch (locale) {
    AppLocale.en => 'Unassigned supplier',
    AppLocale.ru => 'Поставщик не назначен',
    AppLocale.de => 'Nicht zugewiesener Lieferant',
  };

  String get orderHubInvoice => switch (locale) {
    AppLocale.en => 'Order Hub Invoice',
    AppLocale.ru => 'Инвойс Warehub',
    AppLocale.de => 'Warehub-Rechnung',
  };

  String get manualIndex => switch (locale) {
    AppLocale.en => 'Manual Index',
    AppLocale.ru => 'Ручной ввод',
    AppLocale.de => 'Manuell',
  };

  String get selectedInvoice => switch (locale) {
    AppLocale.en => 'Selected Invoice',
    AppLocale.ru => 'Выбранный инвойс',
    AppLocale.de => 'Ausgewählte Rechnung',
  };

  String get openShort => switch (locale) {
    AppLocale.en => 'Open',
    AppLocale.ru => 'Открыто',
    AppLocale.de => 'Offen',
  };

  String get refresh => switch (locale) {
    AppLocale.en => 'Refresh',
    AppLocale.ru => 'Обновить',
    AppLocale.de => 'Aktualisieren',
  };

  String get refreshProfile => switch (locale) {
    AppLocale.en => 'Refresh Profile',
    AppLocale.ru => 'Обновить профиль',
    AppLocale.de => 'Profil aktualisieren',
  };

  String get refreshingProfile => switch (locale) {
    AppLocale.en => 'Refreshing profile...',
    AppLocale.ru => 'Обновляем профиль...',
    AppLocale.de => 'Profil wird aktualisiert...',
  };

  String profileRefreshed(String username) => switch (locale) {
    AppLocale.en => 'Profile refreshed for $username.',
    AppLocale.ru => 'Профиль $username обновлён.',
    AppLocale.de => 'Profil für $username aktualisiert.',
  };

  String get syncWarehub => switch (locale) {
    AppLocale.en => 'Sync Warehub',
    AppLocale.ru => 'Синхронизировать Warehub',
    AppLocale.de => 'Warehub synchronisieren',
  };

  String get syncingWarehub => switch (locale) {
    AppLocale.en => 'Syncing Warehub...',
    AppLocale.ru => 'Синхронизируем Warehub...',
    AppLocale.de => 'Warehub wird synchronisiert...',
  };

  String warehubSyncFinished(int imported, int updated) => switch (locale) {
    AppLocale.en =>
      'Warehub sync finished. $imported imported, $updated updated.',
    AppLocale.ru =>
      'Синхронизация Warehub завершена. Импортировано: $imported, обновлено: $updated.',
    AppLocale.de =>
      'Warehub-Synchronisierung abgeschlossen. $imported importiert, $updated aktualisiert.',
  };

  String get accountConsoleTitle => switch (locale) {
    AppLocale.en => 'Mobile Operator Console',
    AppLocale.ru => 'Мобильная операторская консоль',
    AppLocale.de => 'Mobile Operator-Konsole',
  };

  String get accountConsoleSubtitle => switch (locale) {
    AppLocale.en =>
      'Keep API connectivity, session state and sync actions in one place.',
    AppLocale.ru =>
      'Управляйте API, состоянием сессии и синхронизацией в одном месте.',
    AppLocale.de =>
      'Verwalten Sie API-Verbindung, Sitzungsstatus und Synchronisierung an einem Ort.',
  };

  String get role => switch (locale) {
    AppLocale.en => 'Role',
    AppLocale.ru => 'Роль',
    AppLocale.de => 'Rolle',
  };

  String get created => switch (locale) {
    AppLocale.en => 'Created',
    AppLocale.ru => 'Создан',
    AppLocale.de => 'Erstellt',
  };

  String get unknownUser => switch (locale) {
    AppLocale.en => 'Unknown user',
    AppLocale.ru => 'Неизвестный пользователь',
    AppLocale.de => 'Unbekannter Benutzer',
  };

  String get unknownEmail => switch (locale) {
    AppLocale.en => 'Unknown',
    AppLocale.ru => 'Неизвестно',
    AppLocale.de => 'Unbekannt',
  };

  String get noFiltersFactory => switch (locale) {
    AppLocale.en => 'Factory',
    AppLocale.ru => 'Фабрика',
    AppLocale.de => 'Werk',
  };

  String get allFactories => switch (locale) {
    AppLocale.en => 'All factories',
    AppLocale.ru => 'Все фабрики',
    AppLocale.de => 'Alle Werke',
  };

  String get noFactoriesYet => switch (locale) {
    AppLocale.en => 'Factory index will appear after the first sync.',
    AppLocale.ru => 'Список фабрик появится после первой синхронизации.',
    AppLocale.de =>
      'Die Werksliste erscheint nach der ersten Synchronisierung.',
  };

  String invoiceCount(int count) => switch (locale) {
    AppLocale.en => '$count invoice(s)',
    AppLocale.ru => '$count инвойс(ов)',
    AppLocale.de => '$count Rechnung(en)',
  };

  String invoicesInView(int count) => switch (locale) {
    AppLocale.en => '$count invoice dossier(s) in the current view.',
    AppLocale.ru => 'В текущем представлении $count досье по инвойсам.',
    AppLocale.de => '$count Rechnungsdossier(s) in der aktuellen Ansicht.',
  };

  String uploadedFiles(int count, String backend) => switch (locale) {
    AppLocale.en => '$count file(s) uploaded to $backend.',
    AppLocale.ru => 'Загружено файлов: $count. Хранилище: $backend.',
    AppLocale.de => '$count Datei(en) nach $backend hochgeladen.',
  };

  String formatFactoryRiskOpen(int highRiskCount, String exposure) =>
      switch (locale) {
        AppLocale.en => 'High risk: $highRiskCount | Open: $exposure',
        AppLocale.ru => 'Высокий риск: $highRiskCount | Открыто: $exposure',
        AppLocale.de => 'Hohes Risiko: $highRiskCount | Offen: $exposure',
      };

  String get dangerLabel => switch (locale) {
    AppLocale.en => 'DANGER',
    AppLocale.ru => 'РИСК',
    AppLocale.de => 'GEFAHR',
  };

  String get mapPicker => switch (locale) {
    AppLocale.en => 'Map Location',
    AppLocale.ru => 'Локация на карте',
    AppLocale.de => 'Standort auf Karte',
  };

  String get mapPickerHint => switch (locale) {
    AppLocale.en =>
      'Use current location or edit coordinates manually, then open the map for verification.',
    AppLocale.ru =>
      'Используйте текущую геолокацию или задайте координаты вручную, затем откройте карту для проверки.',
    AppLocale.de =>
      'Verwenden Sie den aktuellen Standort oder bearbeiten Sie Koordinaten manuell und öffnen Sie dann die Karte zur Prüfung.',
  };

  String get loadDashboardFailed => switch (locale) {
    AppLocale.en => 'Failed to load dashboard.',
    AppLocale.ru => 'Не удалось загрузить дашборд.',
    AppLocale.de => 'Dashboard konnte nicht geladen werden.',
  };

  String get loadInvoiceFailed => switch (locale) {
    AppLocale.en => 'Failed to load invoice.',
    AppLocale.ru => 'Не удалось загрузить инвойс.',
    AppLocale.de => 'Rechnung konnte nicht geladen werden.',
  };

  String get createInvoiceFailed => switch (locale) {
    AppLocale.en => 'Failed to create manual invoice.',
    AppLocale.ru => 'Не удалось создать инвойс вручную.',
    AppLocale.de => 'Manuelle Rechnung konnte nicht erstellt werden.',
  };

  String get fileUploadFailed => switch (locale) {
    AppLocale.en => 'File upload failed.',
    AppLocale.ru => 'Не удалось загрузить файл.',
    AppLocale.de => 'Datei-Upload fehlgeschlagen.',
  };

  String get sessionExpired => switch (locale) {
    AppLocale.en => 'Session expired. Please sign in again.',
    AppLocale.ru => 'Сессия истекла. Войдите снова.',
    AppLocale.de => 'Sitzung abgelaufen. Bitte erneut anmelden.',
  };

  String get networkRequestFailed => switch (locale) {
    AppLocale.en =>
      'Network request failed. Check API URL and backend availability.',
    AppLocale.ru =>
      'Сетевой запрос завершился ошибкой. Проверьте URL API и доступность backend.',
    AppLocale.de =>
      'Netzwerkanfrage fehlgeschlagen. Prüfen Sie API-URL und Backend-Verfügbarkeit.',
  };

  String unableToReadFile(String filename) => switch (locale) {
    AppLocale.en => 'Unable to read file $filename.',
    AppLocale.ru => 'Не удалось прочитать файл $filename.',
    AppLocale.de => 'Datei $filename konnte nicht gelesen werden.',
  };

  String translateRole(String? value) =>
      _roleLabels[locale]![value] ?? _roleLabels[locale]!['viewer']!;

  String translateRiskLevel(String? value) =>
      _riskLevelLabels[locale]![value] ?? unset;

  String translateInvoiceStatus(String? value) =>
      _invoiceStatusLabels[locale]![value] ?? _titleize(value ?? 'unknown');

  String translateComplianceChoice(String? value) =>
      _complianceLabels[locale]![value] ??
      _complianceLabels[locale]!['unknown']!;

  String translateDocumentStatus(String? value) =>
      _documentStatusLabels[locale]![value] ??
      _documentStatusLabels[locale]!['missing']!;

  String translateEvidenceSection(String value) =>
      _evidenceSectionLabels[locale]![value] ?? _titleize(value);

  String translateWoodSpecies(String value) =>
      _woodSpeciesLabels[locale]![value] ?? _titleize(value);

  String translateMaterialType(String value) =>
      _materialTypeLabels[locale]![value] ?? _titleize(value);

  String translateBreakdownLabel(String key, String fallback) =>
      _breakdownLabels[locale]![key] ?? fallback;

  String translateAuditAction(String value) =>
      _auditActionLabels[locale]![value] ??
      _titleize(value.replaceAll('.', ' '));

  String translateStorageBackend(String value) =>
      _storageLabels[locale]![value] ?? value;

  String translateBlocker(String blocker) {
    if (locale == AppLocale.en) {
      return blocker;
    }

    final euCountryMatch = RegExp(
      r'^Supplier country (.+) is outside the EU\.$',
    ).firstMatch(blocker);
    if (euCountryMatch != null) {
      final country = euCountryMatch.group(1)!;
      return locale == AppLocale.ru
          ? 'Страна поставщика $country находится вне ЕС.'
          : 'Das Lieferland $country liegt außerhalb der EU.';
    }

    const staticMap = <String, Map<AppLocale, String>>{
      'Certificate is missing.': {
        AppLocale.ru: 'Сертификат отсутствует.',
        AppLocale.de: 'Das Zertifikat fehlt.',
      },
      'Transport papers are missing.': {
        AppLocale.ru: 'Транспортные документы отсутствуют.',
        AppLocale.de: 'Transportdokumente fehlen.',
      },
      'No geolocation proof attached.': {
        AppLocale.ru: 'Нет подтверждения геолокации.',
        AppLocale.de: 'Kein Geolokationsnachweis vorhanden.',
      },
      'Child labor concern flagged.': {
        AppLocale.ru: 'Отмечен риск детского труда.',
        AppLocale.de: 'Hinweis auf Kinderarbeit markiert.',
      },
      'Human rights concern flagged.': {
        AppLocale.ru: 'Отмечен риск по правам человека.',
        AppLocale.de: 'Hinweis auf Menschenrechtsrisiko markiert.',
      },
      'Reviewer marked this invoice as high risk.': {
        AppLocale.ru: 'Ревьюер отметил этот инвойс как высокий риск.',
        AppLocale.de:
            'Der Prüfer hat diese Rechnung als hohes Risiko markiert.',
      },
      'Supplier country is unknown.': {
        AppLocale.ru: 'Страна поставщика неизвестна.',
        AppLocale.de: 'Das Lieferland ist unbekannt.',
      },
      'Wood origin country is not filled.': {
        AppLocale.ru: 'Страна происхождения древесины не заполнена.',
        AppLocale.de: 'Das Ursprungsland des Holzes ist nicht ausgefüllt.',
      },
    };

    return staticMap[blocker]?[locale] ?? blocker;
  }

  String? translateAuditSummary(String? summary) {
    if (summary == null || locale == AppLocale.en) {
      return summary;
    }

    final patterns = locale == AppLocale.ru
        ? <(RegExp, String Function(List<String>))>[
            (
              RegExp(r'^User (.+) signed in\.$'),
              (p) => 'Пользователь ${p[0]} вошёл в систему.',
            ),
            (
              RegExp(r'^Refresh token rotated for (.+)\.$'),
              (p) => 'Refresh token обновлён для ${p[0]}.',
            ),
            (RegExp(r'^Session signed out\.$'), (_) => 'Сессия завершена.'),
            (
              RegExp(r'^User (.+) created\.$'),
              (p) => 'Пользователь ${p[0]} создан.',
            ),
            (
              RegExp(r'^User (.+) updated\.$'),
              (p) => 'Пользователь ${p[0]} обновлён.',
            ),
            (
              RegExp(r'^Bootstrap admin (.+) created\.$'),
              (p) => 'Bootstrap admin ${p[0]} создан.',
            ),
            (
              RegExp(r'^Manual invoice (.+) created\.$'),
              (p) => 'Ручной инвойс ${p[0]} создан.',
            ),
            (
              RegExp(r'^Invoice (.+) metadata updated\.$'),
              (p) => 'Метаданные инвойса ${p[0]} обновлены.',
            ),
            (
              RegExp(r'^Invoice (.+) assessment updated\.$'),
              (p) => 'Оценка инвойса ${p[0]} обновлена.',
            ),
            (
              RegExp(r'^Warehub sync completed for account (.+)\.$'),
              (p) => 'Синхронизация Warehub завершена для аккаунта ${p[0]}.',
            ),
            (
              RegExp(r'^File (.+) uploaded\.$'),
              (p) => 'Файл ${p[0]} загружен.',
            ),
          ]
        : <(RegExp, String Function(List<String>))>[
            (
              RegExp(r'^User (.+) signed in\.$'),
              (p) => 'Benutzer ${p[0]} hat sich angemeldet.',
            ),
            (
              RegExp(r'^Refresh token rotated for (.+)\.$'),
              (p) => 'Refresh-Token für ${p[0]} wurde rotiert.',
            ),
            (
              RegExp(r'^Session signed out\.$'),
              (_) => 'Sitzung wurde beendet.',
            ),
            (
              RegExp(r'^User (.+) created\.$'),
              (p) => 'Benutzer ${p[0]} wurde erstellt.',
            ),
            (
              RegExp(r'^User (.+) updated\.$'),
              (p) => 'Benutzer ${p[0]} wurde aktualisiert.',
            ),
            (
              RegExp(r'^Bootstrap admin (.+) created\.$'),
              (p) => 'Bootstrap-Admin ${p[0]} wurde erstellt.',
            ),
            (
              RegExp(r'^Manual invoice (.+) created\.$'),
              (p) => 'Manuelle Rechnung ${p[0]} wurde erstellt.',
            ),
            (
              RegExp(r'^Invoice (.+) metadata updated\.$'),
              (p) => 'Metadaten der Rechnung ${p[0]} wurden aktualisiert.',
            ),
            (
              RegExp(r'^Invoice (.+) assessment updated\.$'),
              (p) => 'Bewertung der Rechnung ${p[0]} wurde aktualisiert.',
            ),
            (
              RegExp(r'^Warehub sync completed for account (.+)\.$'),
              (p) =>
                  'Warehub-Synchronisierung für Konto ${p[0]} abgeschlossen.',
            ),
            (
              RegExp(r'^File (.+) uploaded\.$'),
              (p) => 'Datei ${p[0]} wurde hochgeladen.',
            ),
          ];

    for (final pattern in patterns) {
      final match = pattern.$1.firstMatch(summary);
      if (match != null) {
        final parts = <String>[
          for (var i = 1; i <= match.groupCount; i += 1)
            if (match.group(i) != null) match.group(i)!,
        ];
        return pattern.$2(parts);
      }
    }

    return summary;
  }

  String _titleize(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
