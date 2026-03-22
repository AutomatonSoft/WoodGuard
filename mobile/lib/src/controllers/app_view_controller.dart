import 'package:flutter/material.dart';

import '../core/app_copy.dart';
import '../services/session_storage.dart';

class AppViewController extends ChangeNotifier {
  AppViewController({SessionStorage? storage})
    : _storage = storage ?? SessionStorage();

  final SessionStorage _storage;

  bool hydrated = false;
  AppLocale _locale = AppLocale.en;
  ThemeMode _themeMode = ThemeMode.light;

  AppLocale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  AppCopy get copy => AppCopy(_locale);

  Future<void> hydrate() async {
    final storedLocale = await _storage.readLocale();
    final storedTheme = await _storage.readThemeMode();

    _locale = storedLocale == null
        ? AppLocaleX.detectFromPlatform()
        : AppLocaleX.fromCode(storedLocale);
    _themeMode = switch (storedTheme) {
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };

    hydrated = true;
    notifyListeners();
  }

  Future<void> setLocale(AppLocale value) async {
    if (_locale == value) {
      return;
    }
    _locale = value;
    await _storage.writeLocale(value.code);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) {
      return;
    }
    _themeMode = value;
    await _storage.writeThemeMode(value == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> toggleTheme() {
    return setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
