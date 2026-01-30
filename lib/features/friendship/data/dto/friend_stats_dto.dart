import '../../domain/entities/friend_stats_entity.dart';

class FriendStatsModel extends FriendStatsEntity {
  const FriendStatsModel({
    required super.totalFriends,
    required super.pendingRequests,
    required super.onlineFriends,
  });

  factory FriendStatsModel.fromJson(Map<String, dynamic> json) {
    return FriendStatsModel(
      totalFriends: json['totalFriends'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      onlineFriends: json['onlineFriends'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFriends': totalFriends,
      'pendingRequests': pendingRequests,
      'onlineFriends': onlineFriends,
    };
  }
}
