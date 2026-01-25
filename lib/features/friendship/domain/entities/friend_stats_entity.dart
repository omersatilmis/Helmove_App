import 'friend_user_entity.dart';

class FriendStatsEntity {
  final int totalFriends;
  final int pendingRequests;
  final int onlineFriends;
  final List<FriendUserEntity> recentFriends;

  const FriendStatsEntity({
    required this.totalFriends,
    required this.pendingRequests,
    required this.onlineFriends,
    this.recentFriends = const [],
  });
}
