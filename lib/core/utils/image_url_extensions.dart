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

  /// Mapbox Static Images URL'inin path'indeki `{width}x{height}@2x` boyut
  /// segmentini hedef boyuta yükseltir. Backend kart için küçük (örn. 600x240@2x)
  /// bir görüntü URL'i döner; tur detayı kapağı tam genişlik + daha yüksek olduğu
  /// için aynı küçük görüntü upscale edilince bulanık/"zoomlanmış" görünür.
  /// Burada yalnızca boyut segmenti büyütülür (token query'de kalır, dokunulmaz).
  /// Mapbox dışı veya beklenen formatta olmayan URL'ler değiştirilmeden döner.
  String toMapboxStaticSize({required int width, required int height}) {
    final raw = (this ?? '').trim();
    if (raw.isEmpty) return '';
    try {
      final uri = Uri.parse(raw);
      if (!uri.host.contains('mapbox')) return raw;
      final segments = List<String>.from(uri.pathSegments);
      if (segments.isEmpty) return raw;

      final last = segments.last;
      final match = RegExp(r'^(\d+)x(\d+)(@2x)?$').firstMatch(last);
      if (match == null) return raw;

      // Mapbox Static Images tek boyut için 1280 üst sınırı uygular.
      final w = width.clamp(1, 1280);
      final h = height.clamp(1, 1280);
      final retina = match.group(3) ?? '@2x';
      segments[segments.length - 1] = '${w}x$h$retina';

      return uri.replace(pathSegments: segments).toString();
    } catch (_) {
      return raw;
    }
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
