import 'package:dio/dio.dart';
import '../datasources/attendance_remote_data_source.dart';
import '../models/participant_model.dart';
import '../models/participation_status_model.dart';

class AttendanceApi implements AttendanceRemoteDataSource {
  final Dio _dio;

  AttendanceApi(this._dio);

  @override
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

  @override
  Future<void> leaveGroupRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/leave');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  @override
  Future<void> approveParticipant(int rideId, int userId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/participants/$userId/approve');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  @override
  Future<void> rejectParticipant(int rideId, int userId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/participants/$userId/reject');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  @override
  Future<List<ParticipantModel>> getRideParticipants(int rideId) async {
    try {
      final response = await _dio.get('/api/GroupRide/$rideId/participants');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ParticipantModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  @override
  Future<ParticipationStatusModel> getParticipationStatus(int rideId) async {
    try {
      final response = await _dio.get(
        '/api/GroupRide/$rideId/participation-status',
      );
      return ParticipationStatusModel.fromJson(response.data['data'] ?? {});
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
