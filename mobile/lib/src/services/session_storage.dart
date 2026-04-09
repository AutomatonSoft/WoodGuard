import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const accessTokenKey = 'woodguard.mobile.access-token';
  static const refreshTokenKey = 'woodguard.mobile.refresh-token';
  static const apiBaseUrlKey = 'woodguard.mobile.api-base-url';
  static const localeKey = 'woodguard.mobile.locale';
  static const themeModeKey = 'woodguard.mobile.theme-mode';

  static String get defaultApiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  static String normalizeApiBaseUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return defaultApiBaseUrl;
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> readAccessToken() {
    return _secureStorage.read(key: accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _secureStorage.read(key: refreshTokenKey);
  }

  Future<void> writeTokens({
    required String? accessToken,
    required String? refreshToken,
  }) async {
    if (accessToken == null || refreshToken == null) {
      await Future.wait<void>([
        _secureStorage.delete(key: accessTokenKey),
        _secureStorage.delete(key: refreshTokenKey),
      ]);
      return;
    }

    await Future.wait<void>([
      _secureStorage.write(key: accessTokenKey, value: accessToken),
      _secureStorage.write(key: refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> readApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(apiBaseUrlKey);
  }

  Future<void> writeApiBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(apiBaseUrlKey, normalizeApiBaseUrl(value));
  }

  Future<String?> readLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(localeKey);
  }

  Future<void> writeLocale(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localeKey, value);
  }

  Future<String?> readThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(themeModeKey);
  }

  Future<void> writeThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, value);
  }
}
