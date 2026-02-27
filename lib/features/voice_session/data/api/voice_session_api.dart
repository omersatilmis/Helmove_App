import 'package:dio/dio.dart';
import '../datasources/voice_session_remote_data_source.dart';
import '../dto/create_voice_session_request_dto.dart';
import '../dto/invite_users_request_dto.dart';
import '../models/voice_session_model.dart';

class VoiceSessionApi implements VoiceSessionRemoteDataSource {
  final Dio _dio;

  VoiceSessionApi(this._dio);

  @override
  Future<int> createSession(CreateVoiceSessionRequestDto request) async {
    try {
      final response = await _dio.post(
        '/api/voice-sessions',
        data: request.toJson(),
      );
      final data = response.data;
      if (data is int) return data;
      if (data is Map<String, dynamic>) {
        final innerData = data['data'];
        if (innerData is int) return innerData;
        if (innerData is Map<String, dynamic>) return innerData['id'] ?? 0;
        return data['id'] ?? 0;
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<VoiceSessionModel> getSession(int id) async {
    try {
      final response = await _dio.get('/api/voice-sessions/$id');
      return VoiceSessionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<List<VoiceSessionModel>> getMySessions() async {
    try {
      final response = await _dio.get('/api/voice-sessions/my-sessions');
      final List<dynamic> dataList = (response.data is Map<String, dynamic>)
          ? (response.data['data'] ?? [])
          : (response.data ?? []);
      return dataList.map((json) => VoiceSessionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> inviteUsers(int id, InviteUsersRequestDto request) async {
    try {
      await _dio.post('/api/voice-sessions/$id/invite', data: request.toJson());
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> acceptInvitation(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/accept');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> rejectInvitation(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/reject');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> joinSession(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/join');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> leaveSession(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/leave');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> endSession(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/end');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> kickUser(int sessionId, int targetUserId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/kick/$targetUserId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> kickParticipant(int rideId, int targetUserId) async {
    try {
      await _dio.post('/api/GroupRide/$rideId/kick/$targetUserId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> promoteParticipant(int sessionId, int targetUserId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/promote/$targetUserId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> demoteParticipant(int sessionId, int targetUserId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/demote/$targetUserId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> muteUser(int sessionId, int targetUserId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/mute/$targetUserId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e));
    }
  }

  @override
  Future<void> transferHost(int sessionId, int newHostId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/transfer/$newHostId');
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
          return 'Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.';
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map<String, dynamic>) {
            return data['message'] ??
                data['title'] ??
                'Sunucu hatası (${error.response?.statusCode})';
          }
          return 'Sunucu hatası (${error.response?.statusCode})';
        case DioExceptionType.cancel:
          return 'İstek iptal edildi.';
        case DioExceptionType.connectionError:
          return 'İnternet bağlantısı yok veya sunucuya erişilemiyor.';
        default:
          return 'Bir ağ hatası oluştu. Lütfen tekrar deneyin.';
      }
    }

    if (error is Map<String, dynamic>) {
      return error['message'] ?? error['title'] ?? 'Bir hata oluştu';
    }

    return error?.toString() ?? 'Bilinmeyen bir hata oluştu';
  }
}
