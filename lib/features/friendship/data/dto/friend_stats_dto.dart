import '../../domain/entities/friend_stats_entity.dart';
import 'friend_user_dto.dart';

class FriendStatsModel extends FriendStatsEntity {
  const FriendStatsModel({
    required super.totalFriends,
    required super.pendingRequests,
    required super.onlineFriends,
    super.recentFriends,
  });

  factory FriendStatsModel.fromJson(Map<String, dynamic> json) {
    return FriendStatsModel(
      totalFriends: json['totalFriends'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      onlineFriends: json['onlineFriends'] ?? 0,
      recentFriends: json['recentFriends'] != null
          ? (json['recentFriends'] as List)
                .map((e) => FriendUserModel.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFriends': totalFriends,
      'pendingRequests': pendingRequests,
      'onlineFriends': onlineFriends,
      'recentFriends': recentFriends
          .map((e) => (e as FriendUserModel).toJson())
          .toList(),
    };
  }
}
