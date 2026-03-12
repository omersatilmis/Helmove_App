import 'package:dio/dio.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../config/mapbox_config.dart';
import '../errors/mapbox_exception.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';

abstract class MapRemoteDataSource {
  Future<LocationModel?> forwardGeocode(String query, {Point? proximity});
  Future<List<LocationModel>> searchLocations(
    String query, {
    Point? proximity,
    CoordinateBounds? bbox,
    List<String>? types,
    int limit = 6,
  });
  Future<LocationModel?> reverseGeocode(Point point, {List<String>? types});
  Future<List<RouteModel>> getRoutes(List<Point> waypoints);
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final Dio dio;

  MapRemoteDataSourceImpl({
    required this.dio,
  });

  void _ensureToken() {
    final token = dio.options.queryParameters['access_token'];
    if (token == null || token.toString().trim().isEmpty) {
      throw const MapboxException(
        'Mapbox access token is missing.',
        type: MapboxErrorType.configuration,
      );
    }
  }

  @override
  Future<LocationModel?> forwardGeocode(String query, {Point? proximity}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;
    _ensureToken();
    try {
      final queryParams = <String, dynamic>{
        'limit': 1,
        'language': MapboxConfig.language,
      };

      if (proximity != null) {
        queryParams['proximity'] =
            '${proximity.coordinates.lng},${proximity.coordinates.lat}';
      }

      final response = await dio.get(
        '/geocoding/v5/mapbox.places/${Uri.encodeComponent(trimmed)}.json',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const MapboxException(
          'Invalid response format.',
          type: MapboxErrorType.invalidResponse,
        );
      }
      final features = data['features'] as List;
      if (features.isEmpty) return null;
      return LocationModel.fromJson(features.first);
    } on DioException catch (e) {
      throw MapboxException.fromDio(e);
    } catch (e) {
      if (e is MapboxException) rethrow;
      throw MapboxException(
        'Unexpected mapbox error.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<LocationModel>> searchLocations(
    String query, {
    Point? proximity,
    CoordinateBounds? bbox,
    List<String>? types,
    int limit = 6,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    _ensureToken();
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'autocomplete': true,
        'language': MapboxConfig.language,
      };

      if (proximity != null) {
        queryParams['proximity'] =
            '${proximity.coordinates.lng},${proximity.coordinates.lat}';
      }

      if (bbox != null && !bbox.infiniteBounds) {
        final sw = bbox.southwest.coordinates;
        final ne = bbox.northeast.coordinates;
        queryParams['bbox'] = '${sw.lng},${sw.lat},${ne.lng},${ne.lat}';
      }

      if (types != null && types.isNotEmpty) {
        queryParams['types'] = types.join(',');
      }

      final response = await dio.get(
        '/geocoding/v5/mapbox.places/${Uri.encodeComponent(trimmed)}.json',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const MapboxException(
          'Invalid response format.',
          type: MapboxErrorType.invalidResponse,
        );
      }
      final features = data['features'] as List;
      if (features.isEmpty) return [];
      return features
          .map((feature) => LocationModel.fromJson(feature))
          .toList();
    } on DioException catch (e) {
      throw MapboxException.fromDio(e);
    } catch (e) {
      if (e is MapboxException) rethrow;
      throw MapboxException(
        'Unexpected mapbox error.',
        originalError: e,
      );
    }
  }

  @override
  Future<LocationModel?> reverseGeocode(Point point, {List<String>? types}) async {
    _ensureToken();
    try {
      final coords = point.coordinates;
      final queryParams = <String, dynamic>{
        'limit': 1,
        'language': MapboxConfig.language,
      };

      if (types != null && types.isNotEmpty) {
        queryParams['types'] = types.join(',');
      }

      final response = await dio.get(
        '/geocoding/v5/mapbox.places/${coords.lng},${coords.lat}.json',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const MapboxException(
          'Invalid response format.',
          type: MapboxErrorType.invalidResponse,
        );
      }
      final features = data['features'] as List;
      if (features.isEmpty) return null;
      return LocationModel.fromJson(features.first);
    } on DioException catch (e) {
      throw MapboxException.fromDio(e);
    } catch (e) {
      if (e is MapboxException) rethrow;
      throw MapboxException(
        'Unexpected mapbox error.',
        originalError: e,
      );
    }
  }

  @override
  Future<List<RouteModel>> getRoutes(List<Point> waypoints) async {
    _ensureToken();
    try {
      if (waypoints.length < 2) return const [];
      
      final coords = waypoints
          .map((p) => '${p.coordinates.lng},${p.coordinates.lat}')
          .join(';');
      final response = await dio.get(
        '/directions/v5/mapbox/driving-traffic/$coords',
        queryParameters: {
          'alternatives': 'true',
          'geometries': 'geojson',
          'overview': 'full',
          'steps': 'true',
          'annotations': 'congestion,duration',
          'language': MapboxConfig.language,
        },
      );
      
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const MapboxException(
          'Invalid response format.',
          type: MapboxErrorType.invalidResponse,
        );
      }
      final routesList = data['routes'] as List;
      return routesList
          .map((json) => RouteModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw MapboxException.fromDio(e);
    } catch (e) {
      if (e is MapboxException) rethrow;
      throw MapboxException(
        'Unexpected mapbox error.',
        originalError: e,
      );
    }
  }
}
