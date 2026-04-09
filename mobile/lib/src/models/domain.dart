Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, data) => MapEntry(key.toString(), data));
  }
  return <String, dynamic>{};
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return <String>[];
}

double _doubleOf(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _nullableDoubleOf(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int _intOf(dynamic value, [int fallback = 0]) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class CountryProfile {
  CountryProfile({
    required this.code,
    required this.name,
    required this.isEu,
    required this.baseRisk,
  });

  final String code;
  final String name;
  final bool isEu;
  final double baseRisk;

  factory CountryProfile.fromJson(Map<String, dynamic> json) {
    return CountryProfile(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isEu: json['is_eu'] == true,
      baseRisk: _doubleOf(json['base_risk']),
    );
  }
}

class Evidence {
  Evidence({this.status = 'missing', this.memo, List<String>? files})
    : files = files ?? <String>[];

  String status;
  String? memo;
  List<String> files;

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      status: json['status']?.toString() ?? 'missing',
      memo: json['memo']?.toString(),
      files: _stringList(json['files']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'memo': memo, 'files': files};
  }

  Evidence clone() => Evidence.fromJson(toJson());
}

class AssessmentPayload {
  AssessmentPayload({
    Evidence? certificate,
    Evidence? locationPictures,
    Evidence? notice,
    Evidence? transportPapers,
    Evidence? geolocationScreenshot,
    Evidence? others,
    List<String>? woodSpecies,
    List<String>? materialTypes,
    this.woodSpecificationMemo,
    this.countryOfOrigin,
    this.quantity,
    this.quantityUnit,
    this.sliceCount,
    this.areaSquareMeters,
    this.deliveryDate,
    this.childLaborOk = 'unknown',
    this.humanRightsOk = 'unknown',
    this.geolocationSourceText,
    this.geolocationLatitude,
    this.geolocationLongitude,
    this.personalRiskLevel,
    this.riskReason,
    this.lastReviewedAt,
  }) : certificate = certificate ?? Evidence(),
       locationPictures = locationPictures ?? Evidence(),
       notice = notice ?? Evidence(),
       transportPapers = transportPapers ?? Evidence(),
       geolocationScreenshot = geolocationScreenshot ?? Evidence(),
       others = others ?? Evidence(),
       woodSpecies = woodSpecies ?? <String>[],
       materialTypes = materialTypes ?? <String>[];

  Evidence certificate;
  Evidence locationPictures;
  Evidence notice;
  Evidence transportPapers;
  Evidence geolocationScreenshot;
  Evidence others;
  List<String> woodSpecies;
  List<String> materialTypes;
  String? woodSpecificationMemo;
  String? countryOfOrigin;
  double? quantity;
  String? quantityUnit;
  int? sliceCount;
  double? areaSquareMeters;
  String? deliveryDate;
  String childLaborOk;
  String humanRightsOk;
  String? geolocationSourceText;
  double? geolocationLatitude;
  double? geolocationLongitude;
  String? personalRiskLevel;
  String? riskReason;
  String? lastReviewedAt;

  factory AssessmentPayload.fromJson(Map<String, dynamic> json) {
    return AssessmentPayload(
      certificate: Evidence.fromJson(_mapOf(json['certificate'])),
      locationPictures: Evidence.fromJson(_mapOf(json['location_pictures'])),
      notice: Evidence.fromJson(_mapOf(json['notice'])),
      transportPapers: Evidence.fromJson(_mapOf(json['transport_papers'])),
      geolocationScreenshot: Evidence.fromJson(
        _mapOf(json['geolocation_screenshot']),
      ),
      others: Evidence.fromJson(_mapOf(json['others'])),
      woodSpecies: _stringList(json['wood_species']),
      materialTypes: _stringList(json['material_types']),
      woodSpecificationMemo: json['wood_specification_memo']?.toString(),
      countryOfOrigin: json['country_of_origin']?.toString(),
      quantity: _nullableDoubleOf(json['quantity']),
      quantityUnit: json['quantity_unit']?.toString(),
      sliceCount: json['slice_count'] == null
          ? null
          : _intOf(json['slice_count']),
      areaSquareMeters: _nullableDoubleOf(json['area_square_meters']),
      deliveryDate: json['delivery_date']?.toString(),
      childLaborOk: json['child_labor_ok']?.toString() ?? 'unknown',
      humanRightsOk: json['human_rights_ok']?.toString() ?? 'unknown',
      geolocationSourceText: json['geolocation_source_text']?.toString(),
      geolocationLatitude: _nullableDoubleOf(json['geolocation_latitude']),
      geolocationLongitude: _nullableDoubleOf(json['geolocation_longitude']),
      personalRiskLevel: json['personal_risk_level']?.toString(),
      riskReason: json['risk_reason']?.toString(),
      lastReviewedAt: json['last_reviewed_at']?.toString(),
    );
  }

  Evidence evidenceFor(String key) {
    switch (key) {
      case 'certificate':
        return certificate;
      case 'location_pictures':
        return locationPictures;
      case 'notice':
        return notice;
      case 'transport_papers':
        return transportPapers;
      case 'geolocation_screenshot':
        return geolocationScreenshot;
      default:
        return others;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'certificate': certificate.toJson(),
      'location_pictures': locationPictures.toJson(),
      'notice': notice.toJson(),
      'transport_papers': transportPapers.toJson(),
      'geolocation_screenshot': geolocationScreenshot.toJson(),
      'others': others.toJson(),
      'wood_species': woodSpecies,
      'material_types': materialTypes,
      'wood_specification_memo': woodSpecificationMemo,
      'country_of_origin': countryOfOrigin,
      'quantity': quantity,
      'quantity_unit': quantityUnit,
      'slice_count': sliceCount,
      'area_square_meters': areaSquareMeters,
      'delivery_date': deliveryDate,
      'child_labor_ok': childLaborOk,
      'human_rights_ok': humanRightsOk,
      'geolocation_source_text': geolocationSourceText,
      'geolocation_latitude': geolocationLatitude,
      'geolocation_longitude': geolocationLongitude,
      'personal_risk_level': personalRiskLevel,
      'risk_reason': riskReason,
      'last_reviewed_at': lastReviewedAt,
    };
  }

  AssessmentPayload clone() => AssessmentPayload.fromJson(toJson());
}

class RiskBreakdownItem {
  RiskBreakdownItem({
    required this.key,
    required this.label,
    required this.weight,
    required this.completed,
    required this.awardedPoints,
  });

  final String key;
  final String label;
  final int weight;
  final bool completed;
  final int awardedPoints;

  factory RiskBreakdownItem.fromJson(Map<String, dynamic> json) {
    return RiskBreakdownItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      weight: _intOf(json['weight']),
      completed: json['completed'] == true,
      awardedPoints: _intOf(json['awarded_points']),
    );
  }
}

class RiskSummary {
  RiskSummary({
    required this.coverageScore,
    required this.coverageTotal,
    required this.coveragePercent,
    required this.penaltyPoints,
    required this.riskScore,
    required this.riskPercent,
    required this.riskLevel,
    List<String>? blockers,
    List<String>? missingSections,
    List<RiskBreakdownItem>? breakdown,
  }) : blockers = blockers ?? <String>[],
       missingSections = missingSections ?? <String>[],
       breakdown = breakdown ?? <RiskBreakdownItem>[];

  final int coverageScore;
  final int coverageTotal;
  final double coveragePercent;
  final int penaltyPoints;
  final double riskScore;
  final double riskPercent;
  final String riskLevel;
  final List<String> blockers;
  final List<String> missingSections;
  final List<RiskBreakdownItem> breakdown;

  factory RiskSummary.fromJson(Map<String, dynamic> json) {
    return RiskSummary(
      coverageScore: _intOf(json['coverage_score']),
      coverageTotal: _intOf(json['coverage_total']),
      coveragePercent: _doubleOf(json['coverage_percent']),
      penaltyPoints: _intOf(json['penalty_points']),
      riskScore: _doubleOf(json['risk_score'], 100),
      riskPercent: _doubleOf(json['risk_percent'], 100),
      riskLevel: json['risk_level']?.toString() ?? 'high',
      blockers: _stringList(json['blockers']),
      missingSections: _stringList(json['missing_sections']),
      breakdown: (json['breakdown'] as List? ?? const [])
          .map((item) => RiskBreakdownItem.fromJson(_mapOf(item)))
          .toList(),
    );
  }
}

class InvoiceSummary {
  InvoiceSummary({
    required this.id,
    this.warehubId,
    required this.source,
    required this.invoiceNumber,
    this.companyName,
    this.companyCountry,
    this.companyCountryName,
    required this.companyIsEu,
    required this.amount,
    required this.totalPaid,
    required this.remainingAmount,
    required this.status,
    this.invoiceDate,
    this.dueDate,
    this.sellerName,
    this.syncedAt,
    required this.risk,
  });

  final int id;
  final int? warehubId;
  final String source;
  String invoiceNumber;
  String? companyName;
  String? companyCountry;
  String? companyCountryName;
  bool companyIsEu;
  double amount;
  double totalPaid;
  double remainingAmount;
  String status;
  String? invoiceDate;
  String? dueDate;
  String? sellerName;
  String? syncedAt;
  RiskSummary risk;

  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    final rawWarehubId = json['warehub_id'];
    return InvoiceSummary(
      id: _intOf(json['id']),
      warehubId: rawWarehubId == null ? null : _intOf(rawWarehubId),
      source: json['source']?.toString() ?? 'manual',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      companyName: json['company_name']?.toString(),
      companyCountry: json['company_country']?.toString(),
      companyCountryName: json['company_country_name']?.toString(),
      companyIsEu: json['company_is_eu'] == true,
      amount: _doubleOf(json['amount']),
      totalPaid: _doubleOf(json['total_paid']),
      remainingAmount: _doubleOf(json['remaining_amount']),
      status: json['status']?.toString() ?? 'unknown',
      invoiceDate: json['invoice_date']?.toString(),
      dueDate: json['due_date']?.toString(),
      sellerName: json['seller_name']?.toString(),
      syncedAt: json['synced_at']?.toString(),
      risk: RiskSummary.fromJson(_mapOf(json['risk'])),
    );
  }
}

class InvoiceDetail extends InvoiceSummary {
  InvoiceDetail({
    required super.id,
    super.warehubId,
    required super.source,
    required super.invoiceNumber,
    super.companyName,
    super.companyCountry,
    super.companyCountryName,
    required super.companyIsEu,
    required super.amount,
    required super.totalPaid,
    required super.remainingAmount,
    required super.status,
    super.invoiceDate,
    super.dueDate,
    super.sellerName,
    super.syncedAt,
    required super.risk,
    this.productionDate,
    this.importDate,
    this.notes,
    this.sellerAddress,
    this.sellerPhone,
    this.sellerEmail,
    this.sellerWebsite,
    this.sellerContactPerson,
    this.sellerGeolocationLabel,
    this.sellerLatitude,
    this.sellerLongitude,
    required this.assessment,
    Map<String, dynamic>? rawPayload,
  }) : rawPayload = rawPayload ?? <String, dynamic>{};

  String? productionDate;
  String? importDate;
  String? notes;
  String? sellerAddress;
  String? sellerPhone;
  String? sellerEmail;
  String? sellerWebsite;
  String? sellerContactPerson;
  String? sellerGeolocationLabel;
  double? sellerLatitude;
  double? sellerLongitude;
  AssessmentPayload assessment;
  Map<String, dynamic> rawPayload;

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    final rawWarehubId = json['warehub_id'];
    return InvoiceDetail(
      id: _intOf(json['id']),
      warehubId: rawWarehubId == null ? null : _intOf(rawWarehubId),
      source: json['source']?.toString() ?? 'manual',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      companyName: json['company_name']?.toString(),
      companyCountry: json['company_country']?.toString(),
      companyCountryName: json['company_country_name']?.toString(),
      companyIsEu: json['company_is_eu'] == true,
      amount: _doubleOf(json['amount']),
      totalPaid: _doubleOf(json['total_paid']),
      remainingAmount: _doubleOf(json['remaining_amount']),
      status: json['status']?.toString() ?? 'unknown',
      invoiceDate: json['invoice_date']?.toString(),
      dueDate: json['due_date']?.toString(),
      sellerName: json['seller_name']?.toString(),
      syncedAt: json['synced_at']?.toString(),
      risk: RiskSummary.fromJson(_mapOf(json['risk'])),
      productionDate: json['production_date']?.toString(),
      importDate: json['import_date']?.toString(),
      notes: json['notes']?.toString(),
      sellerAddress: json['seller_address']?.toString(),
      sellerPhone: json['seller_phone']?.toString(),
      sellerEmail: json['seller_email']?.toString(),
      sellerWebsite: json['seller_website']?.toString(),
      sellerContactPerson: json['seller_contact_person']?.toString(),
      sellerGeolocationLabel: json['seller_geolocation_label']?.toString(),
      sellerLatitude: _nullableDoubleOf(json['seller_latitude']),
      sellerLongitude: _nullableDoubleOf(json['seller_longitude']),
      assessment: AssessmentPayload.fromJson(_mapOf(json['assessment'])),
      rawPayload: _mapOf(json['raw_payload']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehub_id': warehubId,
      'source': source,
      'invoice_number': invoiceNumber,
      'company_name': companyName,
      'company_country': companyCountry,
      'company_country_name': companyCountryName,
      'company_is_eu': companyIsEu,
      'amount': amount,
      'total_paid': totalPaid,
      'remaining_amount': remainingAmount,
      'status': status,
      'invoice_date': invoiceDate,
      'due_date': dueDate,
      'seller_name': sellerName,
      'synced_at': syncedAt,
      'risk': {
        'coverage_score': risk.coverageScore,
        'coverage_total': risk.coverageTotal,
        'coverage_percent': risk.coveragePercent,
        'penalty_points': risk.penaltyPoints,
        'risk_score': risk.riskScore,
        'risk_percent': risk.riskPercent,
        'risk_level': risk.riskLevel,
        'blockers': risk.blockers,
        'missing_sections': risk.missingSections,
        'breakdown': risk.breakdown
            .map(
              (item) => {
                'key': item.key,
                'label': item.label,
                'weight': item.weight,
                'completed': item.completed,
                'awarded_points': item.awardedPoints,
              },
            )
            .toList(),
      },
      'production_date': productionDate,
      'import_date': importDate,
      'notes': notes,
      'seller_address': sellerAddress,
      'seller_phone': sellerPhone,
      'seller_email': sellerEmail,
      'seller_website': sellerWebsite,
      'seller_contact_person': sellerContactPerson,
      'seller_geolocation_label': sellerGeolocationLabel,
      'seller_latitude': sellerLatitude,
      'seller_longitude': sellerLongitude,
      'assessment': assessment.toJson(),
      'raw_payload': rawPayload,
    };
  }

  InvoiceDetail clone() => InvoiceDetail.fromJson(toJson());
}

class InvoiceListResponse {
  InvoiceListResponse({required this.items, required this.total});

  final List<InvoiceSummary> items;
  final int total;

  factory InvoiceListResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceListResponse(
      items: (json['items'] as List? ?? const [])
          .map((item) => InvoiceSummary.fromJson(_mapOf(item)))
          .toList(),
      total: _intOf(json['total']),
    );
  }
}

class FactorySummary {
  FactorySummary({
    required this.name,
    this.country,
    required this.invoiceCount,
    required this.highRiskCount,
    required this.totalAmount,
    required this.remainingAmount,
    required this.invoices,
  });

  final String name;
  final String? country;
  final int invoiceCount;
  final int highRiskCount;
  final double totalAmount;
  final double remainingAmount;
  final List<InvoiceSummary> invoices;

  factory FactorySummary.fromJson(Map<String, dynamic> json) {
    return FactorySummary(
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString(),
      invoiceCount: _intOf(json['invoice_count']),
      highRiskCount: _intOf(json['high_risk_count']),
      totalAmount: _doubleOf(json['total_amount']),
      remainingAmount: _doubleOf(json['remaining_amount']),
      invoices: (json['invoices'] as List? ?? const [])
          .map((item) => InvoiceSummary.fromJson(_mapOf(item)))
          .toList(),
    );
  }
}

class FactoryListResponse {
  FactoryListResponse({
    required this.items,
    required this.total,
    required this.invoiceTotal,
  });

  final List<FactorySummary> items;
  final int total;
  final int invoiceTotal;

  factory FactoryListResponse.fromJson(Map<String, dynamic> json) {
    return FactoryListResponse(
      items: (json['items'] as List? ?? const [])
          .map((item) => FactorySummary.fromJson(_mapOf(item)))
          .toList(),
      total: _intOf(json['total']),
      invoiceTotal: _intOf(json['invoice_total']),
    );
  }
}

class SupplierSummary {
  SupplierSummary({
    required this.name,
    this.country,
    required this.invoiceCount,
    required this.highRiskCount,
    required this.totalAmount,
    required this.remainingAmount,
  });

  final String name;
  final String? country;
  final int invoiceCount;
  final int highRiskCount;
  final double totalAmount;
  final double remainingAmount;

  factory SupplierSummary.fromJson(Map<String, dynamic> json) {
    return SupplierSummary(
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString(),
      invoiceCount: _intOf(json['invoice_count']),
      highRiskCount: _intOf(json['high_risk_count']),
      totalAmount: _doubleOf(json['total_amount']),
      remainingAmount: _doubleOf(json['remaining_amount']),
    );
  }
}

class DashboardMetrics {
  DashboardMetrics({
    required this.totalInvoices,
    required this.paidInvoices,
    required this.openInvoices,
    required this.lowRiskCount,
    required this.mediumRiskCount,
    required this.highRiskCount,
    required this.nonEuSuppliers,
    required this.openExposure,
    required this.averageCoverage,
    this.latestSyncAt,
    required this.suppliers,
  });

  final int totalInvoices;
  final int paidInvoices;
  final int openInvoices;
  final int lowRiskCount;
  final int mediumRiskCount;
  final int highRiskCount;
  final int nonEuSuppliers;
  final double openExposure;
  final double averageCoverage;
  final String? latestSyncAt;
  final List<SupplierSummary> suppliers;

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      totalInvoices: _intOf(json['total_invoices']),
      paidInvoices: _intOf(json['paid_invoices']),
      openInvoices: _intOf(json['open_invoices']),
      lowRiskCount: _intOf(json['low_risk_count']),
      mediumRiskCount: _intOf(json['medium_risk_count']),
      highRiskCount: _intOf(json['high_risk_count']),
      nonEuSuppliers: _intOf(json['non_eu_suppliers']),
      openExposure: _doubleOf(json['open_exposure']),
      averageCoverage: _doubleOf(json['average_coverage']),
      latestSyncAt: json['latest_sync_at']?.toString(),
      suppliers: (json['suppliers'] as List? ?? const [])
          .map((item) => SupplierSummary.fromJson(_mapOf(item)))
          .toList(),
    );
  }
}

class ReferenceOptions {
  ReferenceOptions({
    required this.countries,
    required this.woodSpecies,
    required this.materialTypes,
    required this.documentStatuses,
    required this.riskLevels,
    required this.complianceChoices,
  });

  final List<CountryProfile> countries;
  final List<String> woodSpecies;
  final List<String> materialTypes;
  final List<String> documentStatuses;
  final List<String> riskLevels;
  final List<String> complianceChoices;

  factory ReferenceOptions.fromJson(Map<String, dynamic> json) {
    return ReferenceOptions(
      countries: (json['countries'] as List? ?? const [])
          .map((item) => CountryProfile.fromJson(_mapOf(item)))
          .toList(),
      woodSpecies: _stringList(json['wood_species']),
      materialTypes: _stringList(json['material_types']),
      documentStatuses: _stringList(json['document_statuses']),
      riskLevels: _stringList(json['risk_levels']),
      complianceChoices: _stringList(json['compliance_choices']),
    );
  }
}

class ReverseGeocodeResult {
  ReverseGeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.provider,
  });

  final double latitude;
  final double longitude;
  final String displayName;
  final String provider;

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodeResult(
      latitude: _doubleOf(json['latitude']),
      longitude: _doubleOf(json['longitude']),
      displayName: json['display_name']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'nominatim',
    );
  }
}

class UserPublic {
  UserPublic({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String role;
  final bool isActive;
  final String createdAt;

  factory UserPublic.fromJson(Map<String, dynamic> json) {
    return UserPublic(
      id: _intOf(json['id']),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      role: json['role']?.toString() ?? 'viewer',
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class TokenResponse {
  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshExpiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final int refreshExpiresIn;
  final UserPublic user;

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      expiresIn: _intOf(json['expires_in']),
      refreshExpiresIn: _intOf(json['refresh_expires_in']),
      user: UserPublic.fromJson(_mapOf(json['user'])),
    );
  }
}

class AuditLogEntry {
  AuditLogEntry({
    required this.id,
    this.actorUserId,
    this.actorUsername,
    this.actorRole,
    required this.action,
    required this.entityType,
    this.entityId,
    this.summary,
    Map<String, dynamic>? payload,
    required this.createdAt,
  }) : payload = payload ?? <String, dynamic>{};

  final int id;
  final int? actorUserId;
  final String? actorUsername;
  final String? actorRole;
  final String action;
  final String entityType;
  final String? entityId;
  final String? summary;
  final Map<String, dynamic> payload;
  final String createdAt;

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: _intOf(json['id']),
      actorUserId: json['actor_user_id'] == null
          ? null
          : _intOf(json['actor_user_id']),
      actorUsername: json['actor_username']?.toString(),
      actorRole: json['actor_role']?.toString(),
      action: json['action']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString(),
      summary: json['summary']?.toString(),
      payload: _mapOf(json['payload']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class AuditLogListResponse {
  AuditLogListResponse({required this.items, required this.total});

  final List<AuditLogEntry> items;
  final int total;

  factory AuditLogListResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogListResponse(
      items: (json['items'] as List? ?? const [])
          .map((item) => AuditLogEntry.fromJson(_mapOf(item)))
          .toList(),
      total: _intOf(json['total']),
    );
  }
}

class UploadResponse {
  UploadResponse({
    required this.filename,
    required this.url,
    this.contentType,
    required this.sizeBytes,
    required this.storageBackend,
    this.objectKey,
  });

  final String filename;
  final String url;
  final String? contentType;
  final int sizeBytes;
  final String storageBackend;
  final String? objectKey;

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      filename: json['filename']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      contentType: json['content_type']?.toString(),
      sizeBytes: _intOf(json['size_bytes']),
      storageBackend: json['storage_backend']?.toString() ?? 'local',
      objectKey: json['object_key']?.toString(),
    );
  }
}

class WarehubSyncResult {
  WarehubSyncResult({
    required this.accountId,
    required this.totalReceived,
    required this.imported,
    required this.updated,
    required this.syncedAt,
  });

  final int accountId;
  final int totalReceived;
  final int imported;
  final int updated;
  final String syncedAt;

  factory WarehubSyncResult.fromJson(Map<String, dynamic> json) {
    return WarehubSyncResult(
      accountId: _intOf(json['account_id']),
      totalReceived: _intOf(json['total_received']),
      imported: _intOf(json['imported']),
      updated: _intOf(json['updated']),
      syncedAt: json['synced_at']?.toString() ?? '',
    );
  }
}
