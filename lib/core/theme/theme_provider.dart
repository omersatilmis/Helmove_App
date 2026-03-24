import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Kayıtlı temayı yükle
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = _getModeFromName(savedTheme);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  String get currentThemeName {
    if (_themeMode == ThemeMode.light) return "Aydınlık";
    if (_themeMode == ThemeMode.dark) return "Karanlık";
    return "Sistem";
  }

  // Temayı değiştiren ve kaydeden fonksiyon
  Future<void> setTheme(String themeName) async {
    _themeMode = _getModeFromName(themeName);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeName);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  ThemeMode _getModeFromName(String name) {
    switch (name) {
      case "Aydınlık":
        return ThemeMode.light;
      case "Karanlık":
        return ThemeMode.dark;
      case "Sistem":
      default:
        return ThemeMode.system;
    }
  }
}
