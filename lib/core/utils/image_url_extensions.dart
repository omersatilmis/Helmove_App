import '../network/network_module.dart';

extension ImageUrlOptimization on String? {
  /// Backend relative path'i (/uploads/...) tam URL'e çevirir.
  /// Zaten http/https ile başlıyorsa dokunmaz.
  String toAbsoluteImageUrl() {
    final raw = (this ?? '').trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) {
      final baseUrl = NetworkModule.resolvedBaseUrl;
      final base = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;
      return '$base$raw';
    }
    return raw;
  }

  String toAvatarThumbnail() {
    return _withImageQuery(const {'w': '80', 'q': '70'});
  }

  String toFeedThumbnail() {
    return _withImageQuery(const {'w': '400', 'q': '80'});
  }

  String _withImageQuery(Map<String, String> params) {
    // Önce absolute URL'e çevir, ardından query ekle
    final raw = toAbsoluteImageUrl();
    if (raw.isEmpty) return '';

    try {
      final uri = Uri.parse(raw);
      final scheme = uri.scheme.toLowerCase();
      if (scheme != 'http' && scheme != 'https') {
        return raw;
      }

      final query = Map<String, String>.from(uri.queryParameters);
      query.addAll(params);
      return uri.replace(queryParameters: query).toString();
    } catch (_) {
      return raw;
    }
  }
}
