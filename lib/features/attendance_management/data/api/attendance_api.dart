import 'package:dio/dio.dart';

class AttendanceApi {
  final Dio _dio;

  AttendanceApi(this._dio);

  Future<void> joinGroupRide(int rideId, {String? joinMessage}) async {
    try {
      await _dio.post(
        '/api/GroupRide/$rideId/join',
        data: {'joinMessage': joinMessage},
      );
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> leaveGroupRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/leave');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> approveParticipant(int rideId, int userId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/participants/$userId/approve');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> rejectParticipant(int rideId, int userId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/participants/$userId/reject');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<List<dynamic>> getRideParticipants(int rideId) async {
    try {
      final response = await _dio.get('/api/GroupRide/$rideId/participants');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<dynamic> getParticipationStatus(int rideId) async {
    try {
      final response = await _dio.get(
        '/api/GroupRide/$rideId/participation-status',
      );
      return response.data['data'];
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
