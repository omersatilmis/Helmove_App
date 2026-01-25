import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../dto/friend_request_dto.dart';
import '../dto/friend_stats_dto.dart';
import '../dto/friend_user_dto.dart';
import '../dto/friendship_dto.dart';
import '../../domain/entities/friendship_status.dart';

abstract class FriendshipRemoteDataSource {
  Future<FriendshipModel> sendFriendRequest(int targetUserId, String message);
  Future<FriendshipModel> acceptFriendRequest(int friendshipId);
  Future<FriendshipModel> rejectFriendRequest(int friendshipId);
  Future<FriendshipModel> removeFriend(int friendId);
  Future<FriendshipModel> blockUser(int targetUserId);
  Future<FriendshipModel> unblockUser(int targetUserId);

  Future<List<FriendUserModel>> getMyFriends();
  Future<List<FriendRequestModel>> getPendingRequests();
  Future<List<FriendRequestModel>> getSentRequests();
  Future<FriendStatsModel> getFriendshipStats();
  Future<List<FriendUserModel>> getMutualFriends(int targetUserId);
  Future<List<FriendUserModel>> searchFriends(String query);

  Future<bool> checkAreFriends(int targetUserId);
  Future<FriendshipStatus> getFriendshipStatus(int targetUserId);
}

class FriendshipRemoteDataSourceImpl implements FriendshipRemoteDataSource {
  final Dio dio;

  FriendshipRemoteDataSourceImpl(this.dio);

  @override
  Future<FriendshipModel> sendFriendRequest(
    int targetUserId,
    String message,
  ) async {
    final response = await dio.post(
      ApiEndpoints.sendFriendRequest,
      data: {'targetUserId': targetUserId, 'message': message},
    );
    return FriendshipModel.fromJson(response.data);
  }

  @override
  Future<FriendshipModel> acceptFriendRequest(int friendshipId) async {
    final response = await dio.post(
      ApiEndpoints.acceptFriendRequest(friendshipId),
    );
    return FriendshipModel.fromJson(response.data);
  }

  @override
  Future<FriendshipModel> rejectFriendRequest(int friendshipId) async {
    final response = await dio.post(
      ApiEndpoints.rejectFriendRequest(friendshipId),
    );
    return FriendshipModel.fromJson(response.data);
  }

  @override
  Future<FriendshipModel> removeFriend(int friendId) async {
    final response = await dio.delete(ApiEndpoints.removeFriend(friendId));
    return FriendshipModel.fromJson(response.data);
  }

  @override
  Future<FriendshipModel> blockUser(int targetUserId) async {
    final response = await dio.post(ApiEndpoints.blockUser(targetUserId));
    return FriendshipModel.fromJson(response.data);
  }

  @override
  Future<FriendshipModel> unblockUser(int targetUserId) async {
    final response = await dio.post(ApiEndpoints.unblockUser(targetUserId));
    return FriendshipModel.fromJson(response.data);
  }

  @override
  Future<List<FriendUserModel>> getMyFriends() async {
    final response = await dio.get(ApiEndpoints.myFriends);
    final data = response.data;
    // API Map döndürüyorsa (orn: {"data": [...]}) listeyi çıkar
    final List list = data is List
        ? data
        : (data['data'] ?? data['items'] ?? []);
    return list.map((e) => FriendUserModel.fromJson(e)).toList();
  }

  @override
  Future<List<FriendRequestModel>> getPendingRequests() async {
    final response = await dio.get(ApiEndpoints.pendingRequests);
    final data = response.data;
    final List list = data is List
        ? data
        : (data['data'] ?? data['items'] ?? []);
    return list.map((e) => FriendRequestModel.fromJson(e)).toList();
  }

  @override
  Future<List<FriendRequestModel>> getSentRequests() async {
    final response = await dio.get(ApiEndpoints.sentRequests);
    final data = response.data;
    final List list = data is List
        ? data
        : (data['data'] ?? data['items'] ?? []);
    return list.map((e) => FriendRequestModel.fromJson(e)).toList();
  }

  @override
  Future<FriendStatsModel> getFriendshipStats() async {
    final response = await dio.get(ApiEndpoints.friendshipStats);
    return FriendStatsModel.fromJson(response.data);
  }

  @override
  Future<List<FriendUserModel>> getMutualFriends(int targetUserId) async {
    final response = await dio.get(ApiEndpoints.mutualFriends(targetUserId));
    return (response.data as List)
        .map((e) => FriendUserModel.fromJson(e))
        .toList();
  }

  @override
  Future<List<FriendUserModel>> searchFriends(String query) async {
    final response = await dio.get(
      ApiEndpoints.searchFriends,
      queryParameters: {'searchTerm': query},
    );
    return (response.data as List)
        .map((e) => FriendUserModel.fromJson(e))
        .toList();
  }

  @override
  Future<bool> checkAreFriends(int targetUserId) async {
    final response = await dio.get(ApiEndpoints.areFriends(targetUserId));
    return response.data as bool;
  }

  @override
  Future<FriendshipStatus> getFriendshipStatus(int targetUserId) async {
    final response = await dio.get(ApiEndpoints.friendshipStatus(targetUserId));
    return friendshipStatusFromString(response.data.toString());
  }
}
