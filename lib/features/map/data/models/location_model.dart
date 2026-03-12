import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../domain/entities/location_entity.dart';

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.point,
    required super.label,
    super.id,
    super.placeName,
    super.subtitle,
    super.country,
    super.context,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final center = json['center'] as List<dynamic>;
    final lng = (center[0] as num).toDouble();
    final lat = (center[1] as num).toDouble();
    final placeName = json['text'] as String?;
    final placeNameFull = json['place_name'] as String?;
    final id = json['id'] as String? ?? '';
    
    final context = _parseContext(json['context']);
    final country = _extractCountry(json['context']);
    final subtitle = _buildSmartSubtitle(
      id: id,
      placeName: placeName,
      placeNameFull: placeNameFull,
      contextJson: json['context'],
      fallbackSubtitle: _buildDefaultSubtitle(placeName, placeNameFull, context, country),
    );
    
    final label = _resolveLabel(
      placeNameFull: placeNameFull,
      placeName: placeName,
      lat: lat,
      lng: lng,
    );

    return LocationModel(
      point: Point(coordinates: Position(lng, lat)),
      label: label,
      id: id,
      placeName: placeName,
      subtitle: subtitle,
      country: country,
      context: context,
    );
  }

  static String? _buildSmartSubtitle({
    required String id,
    required String? placeName,
    required String? placeNameFull,
    required dynamic contextJson,
    required String? fallbackSubtitle,
  }) {
    if (contextJson is! List) return fallbackSubtitle;

    final country = _extractCountry(contextJson);

    if (id.startsWith('place.')) {
      // İl (City) seçilirse: sadece ülke (Almanya ve Amerika hariç)
      final isStateRequired = country == 'Germany' ||
          country == 'Almanya' ||
          country == 'USA' ||
          country == 'United States' ||
          country == 'Amerika Birleşik Devletleri';

      if (isStateRequired) {
        final region = _findInContext(contextJson, 'region');
        if (region != null) {
          return country != null ? '$region, $country' : region;
        }
      }
      return country;
    } else if (id.startsWith('district.')) {
      // İlçe seçilirse: bağlı olduğu il ve ülke
      final city =
          _findInContext(contextJson, 'place') ?? _findInContext(contextJson, 'region');
      if (city != null) {
        return country != null ? '$city, $country' : city;
      }
      return country;
    } else if (id.startsWith('neighborhood.') ||
        id.startsWith('locality.') ||
        id.startsWith('suburb.') ||
        id.startsWith('postcode.')) {
      // Mahalle seçilirse: bağlı olduğu ilçe, il ve ülke
      final district = _findInContext(contextJson, 'district');
      final city =
          _findInContext(contextJson, 'place') ?? _findInContext(contextJson, 'region');

      final parts = <String>[];
      if (district != null) parts.add(district);
      if (city != null && city != district) parts.add(city);
      if (country != null) parts.add(country);

      if (parts.isNotEmpty) return parts.join(', ');
      return fallbackSubtitle;
    }

    return fallbackSubtitle;
  }

  static String? _findInContext(List<dynamic> context, String type) {
    for (final entry in context) {
      if (entry is Map<String, dynamic>) {
        final id = entry['id'] as String? ?? '';
        if (id.startsWith('$type.')) {
          return entry['text'] as String?;
        }
      }
    }
    return null;
  }

  static String? _buildDefaultSubtitle(
    String? placeName,
    String? placeNameFull,
    List<String>? context,
    String? country,
  ) {
    final full = placeNameFull?.trim();
    final short = placeName?.trim();

    if (full != null && full.isNotEmpty && short != null && short.isNotEmpty) {
      if (full.startsWith(short)) {
        var remainder = full.substring(short.length).trim();
        if (remainder.startsWith(',')) {
          remainder = remainder.substring(1).trim();
        }
        if (remainder.isNotEmpty) return remainder;
      }
    }

    if (context != null && context.isNotEmpty) {
      return context.join(', ');
    }

    return country?.trim().isNotEmpty == true ? country!.trim() : null;
  }

  static String _resolveLabel({
    required String? placeNameFull,
    required String? placeName,
    required double lat,
    required double lng,
  }) {
    final full = placeNameFull?.trim();
    if (full != null && full.isNotEmpty) return full;
    final short = placeName?.trim();
    if (short != null && short.isNotEmpty) return short;
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  static List<String>? _parseContext(dynamic value) {
    if (value is! List) return null;
    final items = <String>[];
    for (final entry in value) {
      if (entry is Map<String, dynamic>) {
        final text = entry['text'];
        if (text is String && text.trim().isNotEmpty) {
          items.add(text.trim());
        }
      }
    }
    return items.isEmpty ? null : items;
  }

  static String? _extractCountry(dynamic value) {
    if (value is! List) return null;
    for (final entry in value) {
      if (entry is Map<String, dynamic>) {
        final id = entry['id'];
        if (id is String && id.startsWith('country.')) {
          final text = entry['text'];
          if (text is String && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      }
    }
    return null;
  }
}
