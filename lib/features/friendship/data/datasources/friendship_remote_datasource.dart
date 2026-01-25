import '../../domain/entities/friendship_status.dart';
import '../api/friendship_api.dart';
import '../dto/friend_request_dto.dart';
import '../dto/friend_stats_dto.dart';
import '../dto/friend_user_dto.dart';
import '../dto/friendship_dto.dart';

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
  final FriendshipApi api;

  FriendshipRemoteDataSourceImpl(this.api);

  @override
  Future<FriendshipModel> sendFriendRequest(int targetUserId, String message) {
    return api.sendFriendRequest(targetUserId, message);
  }

  @override
  Future<FriendshipModel> acceptFriendRequest(int friendshipId) {
    return api.acceptFriendRequest(friendshipId);
  }

  @override
  Future<FriendshipModel> rejectFriendRequest(int friendshipId) {
    return api.rejectFriendRequest(friendshipId);
  }

  @override
  Future<FriendshipModel> removeFriend(int friendId) {
    return api.removeFriend(friendId);
  }

  @override
  Future<FriendshipModel> blockUser(int targetUserId) {
    return api.blockUser(targetUserId);
  }

  @override
  Future<FriendshipModel> unblockUser(int targetUserId) {
    return api.unblockUser(targetUserId);
  }

  @override
  Future<List<FriendUserModel>> getMyFriends() {
    return api.getMyFriends();
  }

  @override
  Future<List<FriendRequestModel>> getPendingRequests() {
    return api.getPendingRequests();
  }

  @override
  Future<List<FriendRequestModel>> getSentRequests() {
    return api.getSentRequests();
  }

  @override
  Future<FriendStatsModel> getFriendshipStats() {
    return api.getFriendshipStats();
  }

  @override
  Future<List<FriendUserModel>> getMutualFriends(int targetUserId) {
    return api.getMutualFriends(targetUserId);
  }

  @override
  Future<List<FriendUserModel>> searchFriends(String query) {
    return api.searchFriends(query);
  }

  @override
  Future<bool> checkAreFriends(int targetUserId) {
    return api.checkAreFriends(targetUserId);
  }

  @override
  Future<FriendshipStatus> getFriendshipStatus(int targetUserId) {
    return api.getFriendshipStatus(targetUserId);
  }
}
