import 'package:dio/dio.dart';

enum MapboxErrorType {
  network,
  unauthorized,
  rateLimited,
  invalidResponse,
  configuration,
  unknown,
}

class MapboxException implements Exception {
  final String message;
  final MapboxErrorType type;
  final int? statusCode;
  final Object? originalError;

  const MapboxException(
    this.message, {
    this.type = MapboxErrorType.unknown,
    this.statusCode,
    this.originalError,
  });

  factory MapboxException.fromDio(DioException exception) {
    final status = exception.response?.statusCode;
    if (status == 401 || status == 403) {
      return MapboxException(
        'Mapbox authorization failed.',
        type: MapboxErrorType.unauthorized,
        statusCode: status,
        originalError: exception,
      );
    }
    if (status == 429) {
      return MapboxException(
        'Mapbox rate limit exceeded.',
        type: MapboxErrorType.rateLimited,
        statusCode: status,
        originalError: exception,
      );
    }
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError) {
      return MapboxException(
        'Network connection error.',
        type: MapboxErrorType.network,
        statusCode: status,
        originalError: exception,
      );
    }
    return MapboxException(
      'Mapbox request failed.',
      type: MapboxErrorType.unknown,
      statusCode: status,
      originalError: exception,
    );
  }

  @override
  String toString() =>
      'MapboxException(type: $type, statusCode: $statusCode, message: $message)';
}
