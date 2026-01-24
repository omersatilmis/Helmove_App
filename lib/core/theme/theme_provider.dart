import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // Varsayılan olarak sistem temasını kullan
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // UI'da (Ayarlar sayfasında) göstermek için metin hali
  String get currentThemeName {
    if (_themeMode == ThemeMode.light) return "Aydınlık";
    if (_themeMode == ThemeMode.dark) return "Karanlık";
    return "Sistem";
  }

  // Temayı değiştiren fonksiyon
  void setTheme(String themeName) {
    switch (themeName) {
      case "Aydınlık":
        _themeMode = ThemeMode.light;
        break;
      case "Karanlık":
        _themeMode = ThemeMode.dark;
        break;
      case "Sistem":
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    // 🔥 Değişikliği tüm uygulamaya haber ver!
    notifyListeners();
  }
}
