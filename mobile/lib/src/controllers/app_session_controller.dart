import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/domain.dart';
import '../services/session_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class AppSessionController extends ChangeNotifier {
  AppSessionController({SessionStorage? storage, http.Client? httpClient})
    : _storage = storage ?? SessionStorage(),
      _httpClient = httpClient ?? http.Client();

  final SessionStorage _storage;
  final http.Client _httpClient;

  bool hydrated = false;
  bool signingIn = false;
  String _apiBaseUrl = SessionStorage.defaultApiBaseUrl;
  String? _accessToken;
  String? _refreshToken;
  UserPublic? _currentUser;
  Future<bool>? _refreshFuture;

  String get apiBaseUrl => _apiBaseUrl;
  UserPublic? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _accessToken != null && _refreshToken != null && _currentUser != null;

  Future<void> hydrate() async {
    _apiBaseUrl = SessionStorage.normalizeApiBaseUrl(
      await _storage.readApiBaseUrl(),
    );
    _accessToken = await _storage.readAccessToken();
    _refreshToken = await _storage.readRefreshToken();

    if (_accessToken == null || _refreshToken == null) {
      hydrated = true;
      notifyListeners();
      return;
    }

    try {
      _currentUser = await _getMeWithToken(_accessToken!);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        try {
          final refreshed = await _refreshSession();
          if (!refreshed) {
            await _clearSession(notify: false);
          }
        } catch (_) {
          await _clearSession(notify: false);
        }
      } else {
        await _clearSession(notify: false);
      }
    } finally {
      hydrated = true;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String username,
    required String password,
    String? apiBaseUrl,
  }) async {
    signingIn = true;
    notifyListeners();

    try {
      final normalizedApiBaseUrl = SessionStorage.normalizeApiBaseUrl(
        apiBaseUrl ?? _apiBaseUrl,
      );
      _apiBaseUrl = normalizedApiBaseUrl;
      await _storage.writeApiBaseUrl(normalizedApiBaseUrl);

      final response = await _requestJson<TokenResponse>(
        method: 'POST',
        path: '/auth/login',
        body: {'username': username, 'password': password},
        useAuth: false,
        parser: (json) => TokenResponse.fromJson(json),
      );
      await _applyTokenResponse(response);
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut({bool remote = true}) async {
    final refreshToken = _refreshToken;
    if (remote && refreshToken != null) {
      try {
        await _requestJson<Map<String, dynamic>>(
          method: 'POST',
          path: '/auth/logout',
          body: {'refresh_token': refreshToken},
          parser: (json) => json,
        );
      } catch (_) {
        // Best effort only.
      }
    }

    await _clearSession();
  }

  Future<void> setApiBaseUrl(String value) async {
    _apiBaseUrl = SessionStorage.normalizeApiBaseUrl(value);
    await _storage.writeApiBaseUrl(_apiBaseUrl);
    notifyListeners();
  }

  Future<UserPublic> refreshCurrentUser() async {
    final user = await _requestJson<UserPublic>(
      method: 'GET',
      path: '/auth/me',
      parser: (json) => UserPublic.fromJson(json),
    );
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<DashboardMetrics> getMetrics() {
    return _requestJson<DashboardMetrics>(
      method: 'GET',
      path: '/dashboard/metrics',
      parser: (json) => DashboardMetrics.fromJson(json),
    );
  }

  Future<ReferenceOptions> getReferenceOptions() {
    return _requestJson<ReferenceOptions>(
      method: 'GET',
      path: '/reference/options',
      parser: (json) => ReferenceOptions.fromJson(json),
    );
  }

  Future<InvoiceListResponse> getInvoices({
    String? search,
    String? status,
    String? riskLevel,
  }) {
    return _requestJson<InvoiceListResponse>(
      method: 'GET',
      path: '/invoices',
      query: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (riskLevel != null && riskLevel.isNotEmpty) 'risk_level': riskLevel,
      },
      parser: (json) => InvoiceListResponse.fromJson(json),
    );
  }

  Future<InvoiceDetail> getInvoice(int invoiceId) {
    return _requestJson<InvoiceDetail>(
      method: 'GET',
      path: '/invoices/$invoiceId',
      parser: (json) => InvoiceDetail.fromJson(json),
    );
  }

  Future<AuditLogListResponse> getInvoiceAuditLogs(int invoiceId) {
    return _requestJson<AuditLogListResponse>(
      method: 'GET',
      path: '/invoices/$invoiceId/audit-logs',
      parser: (json) => AuditLogListResponse.fromJson(json),
    );
  }

  Future<InvoiceDetail> createManualInvoice(Map<String, Object?> payload) {
    return _requestJson<InvoiceDetail>(
      method: 'POST',
      path: '/invoices',
      body: payload,
      parser: (json) => InvoiceDetail.fromJson(json),
    );
  }

  Future<InvoiceDetail> updateInvoice(
    int invoiceId,
    Map<String, Object?> payload,
  ) {
    return _requestJson<InvoiceDetail>(
      method: 'PUT',
      path: '/invoices/$invoiceId',
      body: payload,
      parser: (json) => InvoiceDetail.fromJson(json),
    );
  }

  Future<InvoiceDetail> updateAssessment(
    int invoiceId,
    Map<String, Object?> payload,
  ) {
    return _requestJson<InvoiceDetail>(
      method: 'PUT',
      path: '/invoices/$invoiceId/assessment',
      body: payload,
      parser: (json) => InvoiceDetail.fromJson(json),
    );
  }

  Future<InvoiceDetail> autofillGeolocation(
    int invoiceId,
    Map<String, Object?> payload,
  ) {
    return _requestJson<InvoiceDetail>(
      method: 'POST',
      path: '/invoices/$invoiceId/geolocation/autofill',
      body: payload,
      parser: (json) => InvoiceDetail.fromJson(json),
    );
  }

  Future<ReverseGeocodeResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    return _requestJson<ReverseGeocodeResult>(
      method: 'GET',
      path: '/reference/reverse-geocode',
      query: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
      parser: (json) => ReverseGeocodeResult.fromJson(json),
    );
  }

  Future<WarehubSyncResult> syncWarehub() {
    return _requestJson<WarehubSyncResult>(
      method: 'POST',
      path: '/invoices/sync/warehub',
      body: const <String, Object?>{},
      parser: (json) => WarehubSyncResult.fromJson(json),
    );
  }

  Future<List<UploadResponse>> uploadEvidence({
    required int invoiceId,
    required String section,
    required List<PlatformFile> files,
  }) async {
    final uploads = <UploadResponse>[];
    for (final file in files) {
      uploads.add(await _uploadSingleFile(invoiceId, section, file));
    }
    return uploads;
  }

  Future<void> _applyTokenResponse(TokenResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _currentUser = response.user;
    await _storage.writeTokens(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
    );
    notifyListeners();
  }

  Future<void> _clearSession({bool notify = true}) async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    await _storage.writeTokens(accessToken: null, refreshToken: null);
    if (notify) {
      notifyListeners();
    }
  }

  Future<UserPublic> _getMeWithToken(String accessToken) async {
    final response = await _sendRequest(
      method: 'GET',
      path: '/auth/me',
      explicitToken: accessToken,
      retry: false,
    );
    final payload = _decodeJson(response);
    return UserPublic.fromJson(payload);
  }

  Future<bool> _refreshSession() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      await _clearSession();
      return false;
    }

    final future = () async {
      try {
        final response = await _requestJson<TokenResponse>(
          method: 'POST',
          path: '/auth/refresh',
          body: {'refresh_token': refreshToken},
          useAuth: false,
          retry: false,
          parser: (json) => TokenResponse.fromJson(json),
        );
        await _applyTokenResponse(response);
        return true;
      } catch (_) {
        await _clearSession();
        return false;
      } finally {
        _refreshFuture = null;
      }
    }();

    _refreshFuture = future;
    return future;
  }

  Future<T> _requestJson<T>({
    required String method,
    required String path,
    Map<String, String>? query,
    Object? body,
    bool useAuth = true,
    bool retry = true,
    required T Function(Map<String, dynamic> json) parser,
  }) async {
    final response = await _sendRequest(
      method: method,
      path: path,
      query: query,
      body: body,
      useAuth: useAuth,
      retry: retry,
    );

    if (response.statusCode == 204) {
      return parser(<String, dynamic>{});
    }

    final payload = _decodeJson(response);
    return parser(payload);
  }

  Future<http.Response> _sendRequest({
    required String method,
    required String path,
    Map<String, String>? query,
    Object? body,
    bool useAuth = true,
    bool retry = true,
    String? explicitToken,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';

    final token = explicitToken ?? (useAuth ? _accessToken : null);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _httpClient.send(request);
    } catch (_) {
      throw ApiException(
        'Network request failed. Check API URL and backend availability.',
        0,
      );
    }

    final response = await http.Response.fromStream(streamedResponse);
    final canRefresh =
        retry && useAuth && path != '/auth/login' && path != '/auth/refresh';
    if (response.statusCode == 401 && canRefresh) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        return _sendRequest(
          method: method,
          path: path,
          query: query,
          body: body,
          useAuth: useAuth,
          retry: false,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        await _clearSession();
      }
      throw ApiException(_readErrorMessage(response), response.statusCode);
    }

    return response;
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{'items': decoded};
  }

  String _readErrorMessage(http.Response response) {
    if (response.body.trim().isEmpty) {
      return response.reasonPhrase ?? 'Request failed.';
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        final message = decoded['message'];
        if (detail is String) {
          return detail;
        }
        if (message is String) {
          return message;
        }
        if (detail != null) {
          return detail.toString();
        }
      }
    } catch (_) {
      return response.body;
    }

    return response.reasonPhrase ?? 'Request failed.';
  }

  Future<UploadResponse> _uploadSingleFile(
    int invoiceId,
    String section,
    PlatformFile file,
  ) async {
    final uri = Uri.parse('$_apiBaseUrl/uploads');
    final request = http.MultipartRequest('POST', uri);
    request.fields['invoice_id'] = invoiceId.toString();
    request.fields['section'] = section;
    request.headers['Accept'] = 'application/json';
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path!));
    } else if (file.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );
    } else {
      throw ApiException('Unable to read file ${file.name}.', 0);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        return _uploadSingleFile(invoiceId, section, file);
      }
      throw ApiException('Session expired. Please sign in again.', 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_readErrorMessage(response), response.statusCode);
    }

    return UploadResponse.fromJson(_decodeJson(response));
  }
}
