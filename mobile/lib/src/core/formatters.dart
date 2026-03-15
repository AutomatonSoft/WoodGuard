import 'package:intl/intl.dart';

import '../models/domain.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'en_US',
  symbol: 'EUR ',
  decimalDigits: 0,
);
final _dateFormatter = DateFormat('dd MMM yyyy');
final _dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm');
final _apiDateFormatter = DateFormat('yyyy-MM-dd');

class EvidenceSection {
  const EvidenceSection(this.key, this.label);

  final String key;
  final String label;
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
  EvidenceSection('certificate', 'Certificate'),
  EvidenceSection('location_pictures', 'Location Pictures'),
  EvidenceSection('notice', 'Notice'),
  EvidenceSection('transport_papers', 'Transport Papers'),
  EvidenceSection('geolocation_screenshot', 'Geolocation Screenshot'),
  EvidenceSection('others', 'Other Evidence'),
];

String formatCurrency(double value) => _currencyFormatter.format(value);

String formatPercent(num? value) => '${(value ?? 0).round()}%';

String formatDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Unset';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return _dateFormatter.format(parsed);
}

String formatDateTime(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Unset';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  return _dateTimeFormatter.format(parsed.toLocal());
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

double? parseNullableDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

String toApiDate(DateTime date) => _apiDateFormatter.format(date);

DateTime? parseApiDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String translateRole(String role) {
  switch (role) {
    case 'admin':
      return 'Admin';
    case 'analyst':
      return 'Analyst';
    case 'reviewer':
      return 'Reviewer';
    default:
      return 'Viewer';
  }
}

String translateRiskLevel(String? level) {
  switch (level) {
    case 'low':
      return 'Low';
    case 'medium':
      return 'Medium';
    case 'high':
      return 'High';
    default:
      return 'Unset';
  }
}

String translateInvoiceStatus(String? status) {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'partial':
      return 'Partial';
    case 'paid':
      return 'Paid';
    case 'cancelled':
      return 'Cancelled';
    case 'draft':
      return 'Draft';
    default:
      return 'Unknown';
  }
}

String translateComplianceChoice(String? choice) {
  switch (choice) {
    case 'yes':
      return 'Yes';
    case 'no':
      return 'No';
    default:
      return 'Unknown';
  }
}

String translateDocumentStatus(String? status) {
  switch (status) {
    case 'verified':
      return 'Verified';
    case 'uploaded':
      return 'Uploaded';
    default:
      return 'Missing';
  }
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
      normalizeText(detail.companyName) != null;
}

String buildCurrentLocationLabel(double latitude, double longitude) {
  return 'Mobile geolocation ${latitude.toStringAsFixed(5)}, '
      '${longitude.toStringAsFixed(5)}';
}

bool shouldReplaceDerivedLocationText(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ||
      normalized.startsWith('Map pin ') ||
      normalized.startsWith('Current location ') ||
      normalized.startsWith('Mobile geolocation ');
}

String buildMapUrl(double latitude, double longitude) {
  return 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude'
      '#map=13/$latitude/$longitude';
}

String absoluteFileUrl(String apiBaseUrl, String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }

  final base = Uri.parse(apiBaseUrl);
  return base.replace(path: path).toString();
}
