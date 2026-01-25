import 'friendship_status.dart';

/// Represents the result of a friendship action (send, accept, etc.)
class FriendshipEntity {
  final int friendshipId;
  final FriendshipStatus status;
  final DateTime? actionDate;
  final String? message;

  const FriendshipEntity({
    required this.friendshipId,
    required this.status,
    this.actionDate,
    this.message,
  });
}
