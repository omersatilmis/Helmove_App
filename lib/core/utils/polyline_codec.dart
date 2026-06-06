import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Encoded Polyline Algorithm Format (Google) — precision 6.
///
/// Grup sürüşünde organizatörün rotası backend'e tek bir string olarak
/// saklanıp tüm üyelere yayılır. Backend bu string'i opak tutar; encode/decode
/// tamamen mobilde yapılır. precision 6 (polyline6) küçük payload + yüksek
/// hassasiyet sağlar.
class PolylineCodec {
  const PolylineCodec._();

  static const int _defaultPrecision = 6;

  /// [points] (Mapbox Point listesi) → encoded polyline string.
  static String encode(List<Point> points, {int precision = _defaultPrecision}) {
    final factor = _factorFor(precision);
    final buffer = StringBuffer();
    int prevLat = 0;
    int prevLng = 0;

    for (final point in points) {
      final lat = (point.coordinates.lat * factor).round();
      final lng = (point.coordinates.lng * factor).round();
      _encodeValue(lat - prevLat, buffer);
      _encodeValue(lng - prevLng, buffer);
      prevLat = lat;
      prevLng = lng;
    }

    return buffer.toString();
  }

  /// encoded polyline string → Mapbox Point listesi.
  static List<Point> decode(
    String encoded, {
    int precision = _defaultPrecision,
  }) {
    final points = <Point>[];
    if (encoded.isEmpty) return points;

    final factor = _factorFor(precision);
    int index = 0;
    int lat = 0;
    int lng = 0;
    final len = encoded.length;

    while (index < len) {
      final latResult = _decodeValue(encoded, index);
      if (latResult == null) break;
      lat += latResult.value;
      index = latResult.nextIndex;

      final lngResult = _decodeValue(encoded, index);
      if (lngResult == null) break;
      lng += lngResult.value;
      index = lngResult.nextIndex;

      points.add(
        Point(coordinates: Position(lng / factor, lat / factor)),
      );
    }

    return points;
  }

  static double _factorFor(int precision) {
    var factor = 1.0;
    for (var i = 0; i < precision; i++) {
      factor *= 10;
    }
    return factor;
  }

  static void _encodeValue(int value, StringBuffer buffer) {
    var v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode((0x20 | (v & 0x1f)) + 63);
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  static _DecodeResult? _decodeValue(String encoded, int startIndex) {
    int index = startIndex;
    int shift = 0;
    int result = 0;
    int byte;
    do {
      if (index >= encoded.length) return null;
      byte = encoded.codeUnitAt(index) - 63;
      index++;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    final value = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    return _DecodeResult(value, index);
  }
}

class _DecodeResult {
  final int value;
  final int nextIndex;
  const _DecodeResult(this.value, this.nextIndex);
}
