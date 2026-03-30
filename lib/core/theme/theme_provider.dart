import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _systemValue = 'system';
  static const String _lightValue = 'light';
  static const String _darkValue = 'dark';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = _parseThemeMode(savedTheme);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  String get currentThemeName {
    if (_themeMode == ThemeMode.light) return _lightValue;
    if (_themeMode == ThemeMode.dark) return _darkValue;
    return _systemValue;
  }

  // Backward-compatible entry point.
  Future<void> setTheme(String themeName) async {
    await setThemeMode(_parseThemeMode(themeName));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _toStorageValue(mode));
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  String _toStorageValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return _lightValue;
      case ThemeMode.dark:
        return _darkValue;
      case ThemeMode.system:
        return _systemValue;
    }
  }

  ThemeMode _parseThemeMode(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case _lightValue:
      case 'aydinlik':
      case 'ayd\u0131nl\u0131k':
      case 'acik':
      case 'a\u00e7\u0131k':
        return ThemeMode.light;
      case _darkValue:
      case 'karanlik':
      case 'karanl\u0131k':
      case 'koyu':
        return ThemeMode.dark;
      case _systemValue:
      case 'sistem':
      default:
        return ThemeMode.system;
    }
  }
}
