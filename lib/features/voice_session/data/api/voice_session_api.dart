import 'package:dio/dio.dart';
import '../dto/create_voice_session_request_dto.dart';
import '../dto/invite_users_request_dto.dart';

class VoiceSessionApi {
  final Dio _dio;

  VoiceSessionApi(this._dio);

  Future<int> createSession(CreateVoiceSessionRequestDto request) async {
    try {
      final response = await _dio.post(
        '/api/voice-sessions',
        data: request.toJson(),
      );
      // Assuming response.data is the ID or contains 'data' with 'id' or is the object with 'id'
      if (response.data is int) {
        return response.data;
      } else if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          if (response.data['data'] is int) return response.data['data'];
          return response.data['data']['id'];
        }
        return response.data['id'];
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<Map<String, dynamic>> getSession(int id) async {
    try {
      final response = await _dio.get('/api/voice-sessions/$id');
      // Backend returns ServiceResponse<SessionDto>: { success, data, message }
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          return response.data['data'];
        }
        return response.data;
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<List<Map<String, dynamic>>> getMySessions() async {
    try {
      final response = await _dio.get('/api/voice-sessions/my-sessions');
      // Backend returns ServiceResponse<List<SessionDto>>: { success, data, message }
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final List<dynamic> list = response.data['data'] ?? [];
        return list.cast<Map<String, dynamic>>();
      } else if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> inviteUsers(int id, InviteUsersRequestDto request) async {
    try {
      await _dio.post('/api/voice-sessions/$id/invite', data: request.toJson());
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> acceptInvitation(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/accept');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> rejectInvitation(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/reject');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> joinSession(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/join');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> leaveSession(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/leave');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> endSession(int id) async {
    try {
      await _dio.post('/api/voice-sessions/$id/end');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> kickUser(int sessionId, int targetUserId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/kick/$targetUserId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> muteUser(int sessionId, int targetUserId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/mute/$targetUserId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> transferHost(int sessionId, int newHostId) async {
    try {
      await _dio.post('/api/voice-sessions/$sessionId/transfer/$newHostId');
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
