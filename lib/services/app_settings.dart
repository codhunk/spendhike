import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_translations.dart';

enum AppLanguage { english, hindi }

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._internal();
  AppSettings._internal();

  static const String _keyLanguage = 'spendhike_app_language';
  static const String _keyThemeMode = 'spendhike_app_theme_mode';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppLanguage get language => _language;
  bool get isHindi => _language == AppLanguage.hindi;

  /// Check if the currently effective appearance is dark given the context
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Load persisted settings on app startup
  Future<void> init() async {
    try {
      final savedLang = await _storage.read(key: _keyLanguage);
      if (savedLang != null && savedLang.isNotEmpty) {
        if (savedLang.toLowerCase() == 'hindi') {
          _language = AppLanguage.hindi;
        } else {
          _language = AppLanguage.english;
        }
      } else {
        _language = AppLanguage.english;
      }
    } catch (e) {
      debugPrint('[AppSettings] Could not load persisted language: $e');
      _language = AppLanguage.english;
    }

    try {
      final savedTheme = await _storage.read(key: _keyThemeMode);
      if (savedTheme != null && savedTheme.isNotEmpty) {
        if (savedTheme == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      } else {
        // Default to system
        _themeMode = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('[AppSettings] Could not load persisted theme: $e');
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    try {
      await _storage.write(
        key: _keyLanguage,
        value: lang == AppLanguage.hindi ? 'hindi' : 'english',
      );
    } catch (e) {
      debugPrint('[AppSettings] Could not persist language: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      String modeStr = 'system';
      if (mode == ThemeMode.light) modeStr = 'light';
      if (mode == ThemeMode.dark) modeStr = 'dark';
      await _storage.write(key: _keyThemeMode, value: modeStr);
    } catch (e) {
      debugPrint('[AppSettings] Could not persist theme mode: $e');
    }
  }

  /// Backward-compatible setTheme boolean
  void setTheme(bool isDark) {
    setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  /// Quick cycle: Light -> Dark -> System -> Light
  Future<void> cycleThemeMode() async {
    final next = switch (_themeMode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
    await setThemeMode(next);
  }

  Future<void> toggleLanguage() async {
    final next = _language == AppLanguage.english ? AppLanguage.hindi : AppLanguage.english;
    await setLanguage(next);
  }

  /// Central translate method
  String tr(String text) {
    return AppTranslations.translate(text, isHindi);
  }
}

/// Global convenience helper
String tr(String key) => AppSettings.instance.tr(key);

/// String extension for easy translation: 'Dashboard'.tr
extension StringTranslationX on String {
  String get tr => AppSettings.instance.tr(this);
}
