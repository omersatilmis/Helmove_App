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
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  String _parseErrorMessage(dynamic data) {
    if (data == null) return 'Bir hata oluştu';
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['title'] ?? 'Bir hata oluştu';
    }
    return data.toString();
  }
}
