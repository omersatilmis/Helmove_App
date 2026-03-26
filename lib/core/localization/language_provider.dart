import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  Locale _locale = const Locale('tr'); // Varsayılan Türkçe

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  // Kayıtlı dili yükle
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null) {
        _locale = Locale(savedLanguage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  String get currentLanguageName {
    if (_locale.languageCode == 'en') return "English";
    return "Türkçe";
  }

  // Dili değiştiren ve kaydeden fonksiyon
  Future<void> setLanguage(String languageName) async {
    final languageCode = _getCodeFromName(languageName);
    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  String _getCodeFromName(String name) {
    switch (name) {
      case "English":
        return "en";
      case "Türkçe":
      default:
        return "tr";
    }
  }
}
