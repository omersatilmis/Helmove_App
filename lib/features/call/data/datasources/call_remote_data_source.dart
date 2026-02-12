import 'package:dio/dio.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/call_models.dart';

abstract class CallRemoteDataSource {
  Future<CallResponseModel> sendCallRequest(CallRequestModel request);
  Future<void> acceptCall(int callId);
  Future<void> rejectCall(int callId);
  Future<void> endCall(int callId);
  Future<OnlineUsersModel> getOnlineUsers();
  Future<bool> isUserOnline(String userId);
  Future<List<CallResponseModel>> getPendingCalls();
}

class CallRemoteDataSourceImpl implements CallRemoteDataSource {
  final Dio client;

  CallRemoteDataSourceImpl({required this.client});

  @override
  Future<CallResponseModel> sendCallRequest(CallRequestModel request) async {
    try {
      final response = await client.post(
        '/api/call/send-request',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CallResponseModel.fromJson(_unwrapMap(response.data));
      }

      throw ServerException(response.statusMessage ?? 'Call request failed');
    } on DioException catch (e) {
      AppLogger.error(
        'REST: Send Call Request Error. '
        'Status: ${e.response?.statusCode}, '
        'Body: ${e.response?.data}',
        e,
      );
      throw ServerException(_extractDioErrorMessage(e));
    }
  }

  @override
  Future<void> acceptCall(int callId) async {
    try {
      final response = await client.post('/api/call/accept/$callId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Call accept failed');
      }
      AppLogger.info('REST: Call Accepted -> ID: $callId');
    } on DioException catch (e) {
      AppLogger.error('REST: Accept Call Error', e);
      throw ServerException(_extractDioErrorMessage(e));
    }
  }

  @override
  Future<void> rejectCall(int callId) async {
    try {
      final response = await client.post('/api/call/reject/$callId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Call reject failed');
      }
      AppLogger.info('REST: Call Rejected -> ID: $callId');
    } on DioException catch (e) {
      AppLogger.error('REST: Reject Call Error', e);
      throw ServerException(_extractDioErrorMessage(e));
    }
  }

  @override
  Future<void> endCall(int callId) async {
    try {
      final response = await client.post('/api/call/end/$callId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Call end failed');
      }
      AppLogger.info('REST: Call Ended -> ID: $callId');
    } on DioException catch (e) {
      AppLogger.error('REST: End Call Error', e);
      throw ServerException(_extractDioErrorMessage(e));
    }
  }

  @override
  Future<OnlineUsersModel> getOnlineUsers() async {
    try {
      final response = await client.get('/api/call/online-users');
      return OnlineUsersModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      AppLogger.error('REST: Get Online Users Error', e);
      throw ServerException(_extractDioErrorMessage(e));
    }
  }

  @override
  Future<bool> isUserOnline(String userId) async {
    try {
      final response = await client.get('/api/call/is-online/$userId');
      if (response.statusCode == 200) {
        if (response.data is bool) return response.data as bool;

        if (response.data is Map) {
          final map = Map<String, dynamic>.from(response.data as Map);
          final value = map['isOnline'] ?? map['data'] ?? map['online'];
          if (value is bool) return value;
          if (value != null) return value.toString().toLowerCase() == 'true';
        }
      }
      return false;
    } on DioException {
      return false;
    }
  }

  @override
  Future<List<CallResponseModel>> getPendingCalls() async {
    try {
      final response = await client.get('/api/call/pending-calls');
      final list = _unwrapList(response.data);
      return list
          .map((e) => CallResponseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      AppLogger.error('REST: Get Pending Calls Error', e);
      return [];
    } catch (e) {
      AppLogger.error('REST: Get Pending Calls Parse Error', e);
      return [];
    }
  }

  Map<String, dynamic> _unwrapMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      return map;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _unwrapList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) return data['data'] as List<dynamic>;
      if (data['items'] is List) return data['items'] as List<dynamic>;
      if (data['result'] is List) return data['result'] as List<dynamic>;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is List) return map['data'] as List<dynamic>;
      if (map['items'] is List) return map['items'] as List<dynamic>;
      if (map['result'] is List) return map['result'] as List<dynamic>;
    }
    return const [];
  }

  String _extractDioErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final message =
          data['message'] ?? data['error'] ?? data['detail'] ?? data['title'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final errors = data['errors'];
      if (errors is Map) {
        final flattened = <String>[];
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            flattened.add('${entry.key}: ${value.join(", ")}');
          } else if (value != null) {
            flattened.add('${entry.key}: $value');
          }
        }
        if (flattened.isNotEmpty) return flattened.join('\n');
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    return e.message ?? 'Unknown server error';
  }
}
