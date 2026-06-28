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
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> leaveGroupRide(int rideId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/leave');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> approveParticipant(int rideId, int userId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/participants/$userId/approve');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> rejectParticipant(int rideId, int userId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/participants/$userId/reject');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<List<ParticipantModel>> getRideParticipants(int rideId) async {
    try {
      final response = await _dio.get('/api/GroupRide/$rideId/participants');
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ParticipantModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<ParticipationStatusModel> getParticipationStatus(int rideId) async {
    try {
      final response = await _dio.get(
        '/api/GroupRide/$rideId/participation-status',
      );
      final data = response.data['data'];
      // Backend bu uçta düz bool ("isParticipating") dönebiliyor; obje değilse
      // fromJson(Map) tip hatası fırlatırdı. Bool/obje/null hepsini tolere et.
      if (data is Map<String, dynamic>) {
        return ParticipationStatusModel.fromJson(data);
      }
      if (data is bool) {
        return ParticipationStatusModel(isParticipating: data);
      }
      return const ParticipationStatusModel(isParticipating: false);
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
