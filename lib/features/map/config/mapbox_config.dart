import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxConfig {
  MapboxConfig._();

  static const String _defaultBaseUrl = 'https://api.mapbox.com';
  static const String _defaultLanguage = 'tr';

  static String get accessToken =>
      (dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '').trim();

  static String get baseUrl {
    final value = (dotenv.env['MAPBOX_BASE_URL'] ?? _defaultBaseUrl).trim();
    return value.isEmpty ? _defaultBaseUrl : value;
  }

  static String get language {
    final value = (dotenv.env['MAPBOX_LANGUAGE'] ?? _defaultLanguage).trim();
    if (value.isNotEmpty) {
      return value;
    }
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final code = locale.languageCode.trim();
      return code.isEmpty ? _defaultLanguage : code;
    } catch (_) {
      return _defaultLanguage;
    }
  }
}
