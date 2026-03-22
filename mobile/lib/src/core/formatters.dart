import 'package:intl/intl.dart';

import '../models/domain.dart';
import 'app_copy.dart';

enum WorkspaceTab { overview, evidence, analytics }

enum FieldTone { positive, negative, warning, neutral }

class EvidenceSection {
  const EvidenceSection(this.key);

  final String key;
}

class FactorySummaryView {
  const FactorySummaryView({
    required this.name,
    required this.country,
    required this.invoiceCount,
    required this.highRiskCount,
    required this.remainingAmount,
  });

  final String name;
  final String? country;
  final int invoiceCount;
  final int highRiskCount;
  final double remainingAmount;
}

const statusOptions = <String>[
  'pending',
  'partial',
  'paid',
  'cancelled',
  'draft',
  'unknown',
];

const complianceOptions = <String>['yes', 'no', 'unknown'];
const personalRiskOptions = <String?>[null, 'low', 'medium', 'high'];

const evidenceSections = <EvidenceSection>[
  EvidenceSection('certificate'),
  EvidenceSection('location_pictures'),
  EvidenceSection('notice'),
  EvidenceSection('transport_papers'),
  EvidenceSection('geolocation_screenshot'),
  EvidenceSection('others'),
];

String _intlLocale(AppLocale locale) => switch (locale) {
  AppLocale.en => 'en_US',
  AppLocale.ru => 'ru_RU',
  AppLocale.de => 'de_DE',
};

String formatCurrency(AppLocale locale, double value) {
  return NumberFormat.currency(
    locale: _intlLocale(locale),
    symbol: 'EUR ',
    decimalDigits: 0,
  ).format(value);
}

String formatPercent(AppLocale locale, num? value) {
  final percent = value ?? 0;
  final number = NumberFormat.decimalPattern(
    _intlLocale(locale),
  ).format(percent.round());
  return '$number%';
}

String formatDate(AppLocale locale, String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppCopy(locale).unset;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return DateFormat.yMMMd(_intlLocale(locale)).format(parsed.toLocal());
}

String formatTime(AppLocale locale, String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppCopy(locale).unset;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return DateFormat.Hm(_intlLocale(locale)).format(parsed.toLocal());
}

String formatDateTime(AppLocale locale, String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppCopy(locale).unset;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return DateFormat.yMMMd(
    _intlLocale(locale),
  ).add_Hm().format(parsed.toLocal());
}

String? normalizeText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String formatNullableDouble(double? value) {
  if (value == null) {
    return '';
  }
  final isWhole = value % 1 == 0;
  return isWhole ? value.toInt().toString() : value.toString();
}

String formatNullableInt(int? value) {
  return value?.toString() ?? '';
}

double? parseNullableDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

int? parseNullableInt(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  return int.tryParse(normalized);
}

String toApiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime? parseApiDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

bool canEditDossier(String? role) {
  return role == 'admin' || role == 'analyst' || role == 'reviewer';
}

bool canCreateManualInvoice(String? role) => canEditDossier(role);

bool canSync(String? role) => role == 'admin' || role == 'analyst';

Map<String, Object?> buildMetadataPayload(InvoiceDetail detail) {
  return {
    'company_name': normalizeText(detail.companyName),
    'company_country': normalizeText(detail.companyCountry)?.toUpperCase(),
    'invoice_date': detail.invoiceDate,
    'production_date': detail.productionDate,
    'import_date': detail.importDate,
    'due_date': detail.dueDate,
    'amount': detail.amount,
    'total_paid': detail.totalPaid,
    'remaining_amount': detail.remainingAmount,
    'status': detail.status,
    'notes': normalizeText(detail.notes),
    'seller_name': normalizeText(detail.sellerName),
    'seller_address': normalizeText(detail.sellerAddress),
    'seller_phone': normalizeText(detail.sellerPhone),
    'seller_email': normalizeText(detail.sellerEmail),
    'seller_website': normalizeText(detail.sellerWebsite),
    'seller_contact_person': normalizeText(detail.sellerContactPerson),
    'seller_geolocation_label': normalizeText(detail.sellerGeolocationLabel),
    'seller_latitude': detail.sellerLatitude,
    'seller_longitude': detail.sellerLongitude,
  };
}

Map<String, Object?> buildAssessmentPayload(InvoiceDetail detail) {
  final payload = detail.assessment.toJson();
  payload['wood_specification_memo'] = normalizeText(
    detail.assessment.woodSpecificationMemo,
  );
  payload['country_of_origin'] = normalizeText(
    detail.assessment.countryOfOrigin,
  )?.toUpperCase();
  payload['quantity_unit'] = normalizeText(detail.assessment.quantityUnit);
  payload['geolocation_source_text'] = normalizeText(
    detail.assessment.geolocationSourceText,
  );
  payload['risk_reason'] = normalizeText(detail.assessment.riskReason);
  return payload;
}

Map<String, Object?> buildAutofillPayload(InvoiceDetail detail) {
  final payload = <String, Object?>{};

  void add(String key, String? value) {
    final normalized = normalizeText(value);
    if (normalized != null) {
      payload[key] = normalized;
    }
  }

  add('company_name', detail.companyName);
  add('company_country', detail.companyCountry?.toUpperCase());
  add('seller_name', detail.sellerName);
  add('seller_address', detail.sellerAddress);
  add('seller_geolocation_label', detail.sellerGeolocationLabel);
  add('geolocation_source_text', detail.assessment.geolocationSourceText);
  return payload;
}

bool hasGeolocationAutofillInput(InvoiceDetail? detail) {
  if (detail == null) {
    return false;
  }
  return normalizeText(detail.assessment.geolocationSourceText) != null ||
      normalizeText(detail.sellerGeolocationLabel) != null ||
      normalizeText(detail.sellerAddress) != null ||
      normalizeText(detail.sellerName) != null ||
      normalizeText(getMeaningfulCompanyName(detail)) != null;
}

String? getMeaningfulCompanyName(InvoiceDetail? detail) {
  final companyName = normalizeText(detail?.companyName);
  if (companyName == null) {
    return null;
  }
  return companyName.toLowerCase() == 'unassigned supplier'
      ? null
      : companyName;
}

String buildCurrentLocationLabel(double latitude, double longitude) {
  return 'Current location ${latitude.toStringAsFixed(5)}, '
      '${longitude.toStringAsFixed(5)}';
}

String buildMapSelectionLabel(double latitude, double longitude) {
  return 'Map pin ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

bool shouldReplaceDerivedLocationText(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ||
      normalized.startsWith('Map pin ') ||
      normalized.startsWith('Current location ');
}

String buildMapUrl(double latitude, double longitude) {
  return 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude'
      '#map=13/$latitude/$longitude';
}

String buildOpenStreetMapEmbedUrl(double latitude, double longitude) {
  const delta = 0.03;
  final left = longitude - delta;
  final right = longitude + delta;
  final top = latitude + delta;
  final bottom = latitude - delta;
  return 'https://www.openstreetmap.org/export/embed.html?bbox='
      '$left%2C$bottom%2C$right%2C$top&layer=mapnik&marker=$latitude%2C$longitude';
}

String formatCoordinate(double? value) {
  return value == null ? '--' : value.toStringAsFixed(6);
}

String absoluteFileUrl(String apiBaseUrl, String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  final apiUri = Uri.parse(apiBaseUrl);
  final origin = Uri(
    scheme: apiUri.scheme,
    host: apiUri.host,
    port: apiUri.hasPort ? apiUri.port : null,
  );
  return origin.resolve(path.startsWith('/') ? path : '/$path').toString();
}

String resolveFactoryName(InvoiceSummary invoice, String fallback) {
  return normalizeText(invoice.sellerName) ??
      normalizeText(invoice.companyName) ??
      fallback;
}

List<FactorySummaryView> buildFactorySummaries(
  List<InvoiceSummary> items,
  String fallback,
) {
  final factories = <String, FactorySummaryView>{};

  for (final invoice in items) {
    final name = resolveFactoryName(invoice, fallback);
    final current =
        factories[name] ??
        FactorySummaryView(
          name: name,
          country: invoice.companyCountryName ?? invoice.companyCountry,
          invoiceCount: 0,
          highRiskCount: 0,
          remainingAmount: 0,
        );

    factories[name] = FactorySummaryView(
      name: name,
      country:
          current.country ??
          invoice.companyCountryName ??
          invoice.companyCountry,
      invoiceCount: current.invoiceCount + 1,
      highRiskCount:
          current.highRiskCount + (invoice.risk.riskLevel == 'high' ? 1 : 0),
      remainingAmount: current.remainingAmount + invoice.remainingAmount,
    );
  }

  final result = factories.values.toList();
  result.sort((left, right) {
    if (right.highRiskCount != left.highRiskCount) {
      return right.highRiskCount.compareTo(left.highRiskCount);
    }
    if (right.invoiceCount != left.invoiceCount) {
      return right.invoiceCount.compareTo(left.invoiceCount);
    }
    return left.name.compareTo(right.name);
  });
  return result;
}

FieldTone getComplianceTone(String? value) {
  switch (value) {
    case 'yes':
      return FieldTone.positive;
    case 'no':
      return FieldTone.negative;
    default:
      return FieldTone.warning;
  }
}

FieldTone getRiskTone(String? value) {
  switch (value) {
    case 'low':
      return FieldTone.positive;
    case 'high':
      return FieldTone.negative;
    case 'medium':
      return FieldTone.warning;
    default:
      return FieldTone.neutral;
  }
}

String translateRole(String? role, {AppLocale locale = AppLocale.en}) {
  return AppCopy(locale).translateRole(role);
}

String translateRiskLevel(String? value, {AppLocale locale = AppLocale.en}) {
  return AppCopy(locale).translateRiskLevel(value);
}

String translateInvoiceStatus(
  String? value, {
  AppLocale locale = AppLocale.en,
}) {
  return AppCopy(locale).translateInvoiceStatus(value);
}

String translateComplianceChoice(
  String? value, {
  AppLocale locale = AppLocale.en,
}) {
  return AppCopy(locale).translateComplianceChoice(value);
}

String translateDocumentStatus(
  String? value, {
  AppLocale locale = AppLocale.en,
}) {
  return AppCopy(locale).translateDocumentStatus(value);
}

String translateEvidenceSection(
  String value, {
  AppLocale locale = AppLocale.en,
}) {
  return AppCopy(locale).translateEvidenceSection(value);
}

String translateWoodSpecies(String value, {AppLocale locale = AppLocale.en}) {
  return AppCopy(locale).translateWoodSpecies(value);
}

String translateMaterialType(String value, {AppLocale locale = AppLocale.en}) {
  return AppCopy(locale).translateMaterialType(value);
}
