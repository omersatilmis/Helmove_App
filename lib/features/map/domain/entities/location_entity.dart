import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class LocationEntity {
  static const selectedLocationLabel = 'Se\u00e7ili Konum';

  final Point point;
  final String label;
  final String? id;
  final String? placeName;
  final String? subtitle;
  final String? country;
  final List<String>? context;

  const LocationEntity({
    required this.point,
    required this.label,
    this.id,
    this.placeName,
    this.subtitle,
    this.country,
    this.context,
  });

  LocationEntity copyWith({
    Point? point,
    String? label,
    String? id,
    String? placeName,
    String? subtitle,
    String? country,
    List<String>? context,
  }) {
    return LocationEntity(
      point: point ?? this.point,
      label: label ?? this.label,
      id: id ?? this.id,
      placeName: placeName ?? this.placeName,
      subtitle: subtitle ?? this.subtitle,
      country: country ?? this.country,
      context: context ?? this.context,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationEntity &&
          runtimeType == other.runtimeType &&
          point.coordinates.lng == other.point.coordinates.lng &&
          point.coordinates.lat == other.point.coordinates.lat &&
          label == other.label &&
          id == other.id &&
          placeName == other.placeName &&
          subtitle == other.subtitle &&
          country == other.country &&
          listEquals(context, other.context);

  @override
  int get hashCode => Object.hash(
        point.coordinates.lng,
        point.coordinates.lat,
        label,
        id,
        placeName,
        subtitle,
        country,
        context == null ? null : Object.hashAll(context!),
      );
}
