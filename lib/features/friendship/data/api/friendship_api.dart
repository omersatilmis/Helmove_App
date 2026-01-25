import 'package:dio/dio.dart';
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
      return FriendshipModel.fromJson(response.data);
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
      return FriendshipModel.fromJson(response.data);
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
      return FriendshipModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Arkadaşlık isteği reddedilemedi');
    }
  }

  /// DELETE /api/Friendship/remove/{friendId}
  Future<FriendshipModel> removeFriend(int friendId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.removeFriend(friendId));
      return FriendshipModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Arkadaş silinemedi');
    }
  }

  /// POST /api/Friendship/block/{targetUserId}
  Future<FriendshipModel> blockUser(int targetUserId) async {
    try {
      final response = await _dio.post(ApiEndpoints.blockUser(targetUserId));
      return FriendshipModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e, 'Kişi engellenemedi');
    }
  }

  /// POST /api/Friendship/unblock/{targetUserId}
  Future<FriendshipModel> unblockUser(int targetUserId) async {
    try {
      final response = await _dio.post(ApiEndpoints.unblockUser(targetUserId));
      return FriendshipModel.fromJson(response.data);
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
  Future<FriendStatsModel> getFriendshipStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.friendshipStats);
      return FriendStatsModel.fromJson(response.data);
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
      return friendshipStatusFromString(response.data.toString());
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
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          '$defaultMessage: ${e.response?.statusCode}';
      return Exception(errorMessage);
    }
    return Exception("$defaultMessage: $e");
  }

  String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['message'] ??
          data['detail'] ??
          data['error'] ??
          data['description'];
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
}
