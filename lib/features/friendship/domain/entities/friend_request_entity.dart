import 'friendship_status.dart';

class FriendRequestEntity {
  final int id;
  final int requesterId;
  final String requesterUsername;
  final String? requesterName;
  final String? requesterProfilePicture;
  // Receiver fields for sent requests
  final int? receiverId;
  final String? receiverUsername;
  final String? receiverName;
  final String? receiverProfilePicture;
  final String? message;
  final DateTime? requestedAt;
  final FriendshipStatus status;

  const FriendRequestEntity({
    required this.id,
    required this.requesterId,
    required this.requesterUsername,
    this.requesterName,
    this.requesterProfilePicture,
    this.receiverId,
    this.receiverUsername,
    this.receiverName,
    this.receiverProfilePicture,
    this.message,
    this.requestedAt,
    required this.status,
  });
}
