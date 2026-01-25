import 'friendship_status.dart';

class FriendRequestEntity {
  final int id;
  final int requesterId;
  final String requesterUsername;
  final String? requesterName;
  final String? requesterProfilePicture;
  final String? message;
  final DateTime? requestedAt;
  final FriendshipStatus status;

  const FriendRequestEntity({
    required this.id,
    required this.requesterId,
    required this.requesterUsername,
    this.requesterName,
    this.requesterProfilePicture,
    this.message,
    this.requestedAt,
    required this.status,
  });
}
