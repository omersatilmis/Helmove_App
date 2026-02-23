import 'package:dio/dio.dart';

class StatusApi {
  final Dio _dio;

  StatusApi(this._dio);

  Future<void> startRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/start');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> completeRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/complete');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> cancelRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/cancel');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> postponeRide(int rideId, DateTime newDateTime) async {
    try {
      await _dio.post(
        '/api/GroupRide/$rideId/postpone',
        data: {'newDateTime': newDateTime.toIso8601String()},
      );
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  String _parseErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Bağlantı zaman aşımına uğradı.';
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map<String, dynamic>) {
            return data['message'] ??
                data['title'] ??
                'Sunucu hatası (${error.response?.statusCode})';
          }
          return 'Sunucu hatası (${error.response?.statusCode})';
        case DioExceptionType.connectionError:
          return 'İnternet bağlantısı yok.';
        default:
          return 'Bir ağ hatası oluştu.';
      }
    }
    if (error is Map<String, dynamic>) {
      return error['message'] ?? error['title'] ?? 'Bir hata oluştu';
    }
    return error?.toString() ?? 'Bilinmeyen bir hata oluştu';
  }
}
