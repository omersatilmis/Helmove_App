import 'package:dio/dio.dart';
import '../models/call_models.dart';

class CallApi {
  final Dio _dio;

  CallApi(this._dio);

  Future<CallResponseModel> sendCallRequest(CallRequestModel request) async {
    try {
      final response = await _dio.post(
        '/api/call/send-request',
        data: request.toJson(),
      );
      return CallResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> acceptCall(int callId) async {
    try {
      await _dio.post('/api/call/accept/$callId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> rejectCall(int callId) async {
    try {
      await _dio.post('/api/call/reject/$callId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<void> endCall(int callId) async {
    try {
      await _dio.post('/api/call/end/$callId');
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<OnlineUsersModel> getOnlineUsers() async {
    try {
      final response = await _dio.get('/api/call/online-users');
      return OnlineUsersModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<bool> isUserOnline(String userId) async {
    try {
      final response = await _dio.get('/api/call/is-online/$userId');
      // Swagger says "Kullanıcı durumu başarıyla getirildi", usually returns bool or { isOnline: bool }
      // I'll assume response.data is bool or contains it.
      if (response.data is bool) return response.data;
      if (response.data is Map) return response.data['isOnline'] ?? false;
      return false;
    } on DioException catch (e) {
      throw Exception(_parseErrorMessage(e.response?.data));
    }
  }

  Future<List<CallResponseModel>> getPendingCalls() async {
    try {
      final response = await _dio.get('/api/call/pending-calls');
      final List<dynamic> data =
          response.data; // or response.data['data'] if nested
      return data.map((json) => CallResponseModel.fromJson(json)).toList();
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
