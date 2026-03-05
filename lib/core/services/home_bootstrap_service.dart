import 'package:dio/dio.dart';

import '../models/home_bootstrap_response.dart';

class HomeBootstrapService {
  final Dio _dio;
  bool _isEndpointUnavailable = false;
  final Map<int, Future<HomeBootstrapResponse?>> _inFlightByLimit =
      <int, Future<HomeBootstrapResponse?>>{};

  HomeBootstrapService(this._dio);

  Future<HomeBootstrapResponse?> getHomeBootstrap({int limit = 10}) async {
    if (_isEndpointUnavailable) {
      return null;
    }

    final inFlight = _inFlightByLimit[limit];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchHomeBootstrap(limit: limit);
    _inFlightByLimit[limit] = future;
    try {
      return await future;
    } finally {
      _inFlightByLimit.remove(limit);
    }
  }

  Future<HomeBootstrapResponse?> _fetchHomeBootstrap({
    required int limit,
  }) async {
    try {
      final response = await _dio.get(
        '/api/home/bootstrap',
        queryParameters: {'limit': limit},
      );
      final payload = _extractPayload(response.data);
      if (payload == null) {
        return null;
      }
      return HomeBootstrapResponse.fromJson(payload, fallbackLimit: limit);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _isEndpointUnavailable = true;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<HomeBootstrapResponse?> getBootstrap({int limit = 10}) {
    return getHomeBootstrap(limit: limit);
  }

  Map<String, dynamic>? _extractPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final data = map['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return map;
    }
    return null;
  }
}
