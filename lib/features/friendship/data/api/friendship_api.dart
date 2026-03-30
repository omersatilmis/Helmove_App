import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'friendship_endpoints.dart';
import '../../domain/entities/friendship_status.dart';
import '../dto/friend_request_dto.dart';
import '../dto/friend_stats_dto.dart';
import '../dto/friend_user_dto.dart';
import '../dto/friendship_dto.dart';

class FriendshipApi {
  final Dio _dio;

  FriendshipApi(this._dio);

  /// POST /api/Friendship/send-request
  Future<FriendshipModel> sendFriendRequest(
    int targetUserId,
    String message,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.sendFriendRequest,
        data: {'targetUserId': targetUserId, 'message': message},
      );
      return FriendshipModel.fromJson(_extractPayloadMap(response.data));
    } catch (e) {
      throw _handleError(e, 'Arkadaşlık isteği gönderilemedi');
    }
  }

  /// POST /api/Friendship/accept/{friendshipId}
  Future<FriendshipModel> acceptFriendRequest(int friendshipId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.acceptFriendRequest(friendshipId),
      );
      return FriendshipModel.fromJson(_extractPayloadMap(response.data));
    } catch (e) {
      throw _handleError(e, 'Arkadaşlık isteği kabul edilemedi');
    }
  }

  /// POST /api/Friendship/reject/{friendshipId}
  Future<FriendshipModel> rejectFriendRequest(int friendshipId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.rejectFriendRequest(friendshipId),
      );
      return FriendshipModel.fromJson(_extractPayloadMap(response.data));
    } catch (e) {
      throw _handleError(e, 'Arkadaşlık isteği reddedilemedi');
    }
  }

  /// DELETE /api/Friendship/cancel/{friendshipId}
  Future<FriendshipModel> cancelSentRequest(int friendshipId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.cancelSentRequest(friendshipId),
      );
      return FriendshipModel.fromJson(_extractPayloadMap(response.data));
    } catch (e) {
      throw _handleError(e, 'Gonderilen istek iptal edilemedi');
    }
  }

  /// DELETE /api/Friendship/remove/{friendId}
  Future<FriendshipModel> removeFriend(int friendId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.removeFriend(friendId));
      return FriendshipModel.fromJson(_extractPayloadMap(response.data));
    } catch (e) {
      throw _handleError(e, 'Arkadaş silinemedi');
    }
  }

  /// POST /api/Friendship/block/{targetUserId}
  Future<FriendshipModel> blockUser(int targetUserId) async {
    try {
      final response = await _dio.post(ApiEndpoints.blockUser(targetUserId));
      return FriendshipModel.fromJson(_extractPayloadMap(response.data));
    } catch (e) {
      throw _handleError(e, 'Kişi engellenemedi');
    }
  }

  /// POST /api/Friendship/unblock/{targetUserId}
  Future<FriendshipModel> unblockUser(int targetUserId) async {
    try {
      final response = await _dio.post(ApiEndpoints.unblockUser(targetUserId));
      return FriendshipModel.fromJson(_extractPayloadMap(response.data));
    } catch (e) {
      throw _handleError(e, 'Engel kaldırılamadı');
    }
  }

  /// GET /api/Friendship/my-friends
  Future<List<FriendUserModel>> getMyFriends() async {
    try {
      final response = await _dio.get(ApiEndpoints.myFriends);
      return _parseList(
        response.data,
        (json) => FriendUserModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'Arkadaş listesi alınamadı');
    }
  }

  /// GET /api/Friendship/friends/{userId}
  Future<List<FriendUserModel>> getFriends(int userId) async {
    try {
      final response = await _dio.get(ApiEndpoints.friends(userId));
      return _parseList(
        response.data,
        (json) => FriendUserModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'Arkadas listesi alinamadi');
    }
  }

  /// GET /api/Friendship/pending-requests
  Future<List<FriendRequestModel>> getPendingRequests() async {
    try {
      final response = await _dio.get(ApiEndpoints.pendingRequests);
      return _parseList(
        response.data,
        (json) => FriendRequestModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'Bekleyen istekler alınamadı');
    }
  }

  /// GET /api/Friendship/sent-requests
  Future<List<FriendRequestModel>> getSentRequests() async {
    try {
      final response = await _dio.get(ApiEndpoints.sentRequests);
      return _parseList(
        response.data,
        (json) => FriendRequestModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'Gönderilen istekler alınamadı');
    }
  }

  /// GET /api/Friendship/stats
  Future<FriendStatsModel> getFriendshipStats({int? userId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['targetUserId'] = userId;
      }

      final response = await _dio.get(
        ApiEndpoints.friendshipStats,
        queryParameters: queryParams,
      );

      dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          data = data['data'];
        } else if (data.containsKey('result')) {
          data = data['result'];
        }
      }

      return FriendStatsModel.fromJson(data);
    } catch (e) {
      throw _handleError(e, 'İstatistikler alınamadı');
    }
  }

  /// GET /api/Friendship/mutual-friends/{targetUserId}
  Future<List<FriendUserModel>> getMutualFriends(int targetUserId) async {
    try {
      final response = await _dio.get(ApiEndpoints.mutualFriends(targetUserId));
      return _parseList(
        response.data,
        (json) => FriendUserModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'Ortak arkadaşlar alınamadı');
    }
  }

  /// GET /api/Friendship/search
  Future<List<FriendUserModel>> searchFriends(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.searchFriends,
        queryParameters: {'searchTerm': query},
      );
      return _parseList(
        response.data,
        (json) => FriendUserModel.fromJson(json),
      );
    } catch (e) {
      throw _handleError(e, 'Arama başarısız');
    }
  }

  /// GET /api/Friendship/are-friends/{targetUserId}
  Future<bool> checkAreFriends(int targetUserId) async {
    try {
      final response = await _dio.get(ApiEndpoints.areFriends(targetUserId));
      return response.data as bool;
    } catch (e) {
      throw _handleError(e, 'Arkadaşlık durumu kontrol edilemedi');
    }
  }

  /// GET /api/Friendship/friendship-status/{targetUserId}
  Future<FriendshipStatus> getFriendshipStatus(int targetUserId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.friendshipStatus(targetUserId),
      );

      dynamic data = response.data;

      // 1. Unwrap common wrappers like "data", "result", "value"
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          data = data['data'];
        } else if (data.containsKey('result')) {
          data = data['result'];
        } else if (data.containsKey('value')) {
          data = data['value'];
        }
      }

      // 2. Extract Status from Object or Primitive
      String statusStr = "";

      if (data is Map<String, dynamic>) {
        if (data.containsKey('status')) {
          statusStr = data['status'].toString();
        } else if (data.containsKey('friendshipStatus')) {
          statusStr = data['friendshipStatus'].toString();
        } else {
          // Fallback: try to see if the map itself has an enum string
          statusStr = data.toString();
        }
      } else {
        // Primitive (int, string, etc.)
        statusStr = data?.toString() ?? "";
      }

      debugPrint(
        "🔍 Friendship Status RAW [User: $targetUserId]: $data | Parsed: $statusStr",
      );

      return friendshipStatusFromString(statusStr);
    } catch (e) {
      throw _handleError(e, 'Arkadaşlık durumu alınamadı');
    }
  }

  // --- Helpers ---

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List list = data is List
        ? data
        : (data['data'] ?? data['items'] ?? []);
    return list.map((e) => fromJson(e)).toList();
  }

  Exception _handleError(dynamic e, String defaultMessage) {
    if (e is DioException) {
      final parsedMessage = _parseErrorMessage(e.response?.data);
      final statusCode = e.response?.statusCode;
      final fallbackMessage = statusCode != null
          ? '$defaultMessage (HTTP $statusCode)'
          : defaultMessage;
      final errorMessage = _normalizeMessage(parsedMessage) ?? fallbackMessage;
      return Exception(errorMessage);
    }
    return Exception("$defaultMessage: $e");
  }

  String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final directMessage =
          data['message'] ??
          data['detail'] ??
          data['error'] ??
          data['description'] ??
          data['title'];

      if (_normalizeMessage(directMessage) != null) {
        return directMessage.toString();
      }

      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value != null) {
            return value.toString();
          }
        }
      }
      return null;
    }
    if (data is String) return data;
    if (data is List && data.isNotEmpty) {
      final firstItem = data.first;
      return firstItem is Map
          ? (firstItem['description'] ??
                firstItem['message'] ??
                firstItem.toString())
          : firstItem.toString();
    }
    return data.toString();
  }

  String? _normalizeMessage(dynamic rawMessage) {
    if (rawMessage == null) return null;
    final message = rawMessage.toString().trim();
    if (message.isEmpty || message == 'Exception:' || message == 'Exception') {
      return null;
    }
    return message;
  }

  Map<String, dynamic> _extractPayloadMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      if (data['result'] is Map<String, dynamic>) {
        return data['result'] as Map<String, dynamic>;
      }
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data']);
      }
      if (map['result'] is Map) {
        return Map<String, dynamic>.from(map['result']);
      }
      return map;
    }
    return <String, dynamic>{};
  }
}
