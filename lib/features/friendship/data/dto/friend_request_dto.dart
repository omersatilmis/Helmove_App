import '../../domain/entities/friend_request_entity.dart';
import '../../domain/entities/friendship_status.dart';

class FriendRequestModel extends FriendRequestEntity {
  const FriendRequestModel({
    required super.id,
    required super.requesterId,
    required super.requesterUsername,
    super.requesterName,
    super.requesterProfilePicture,
    super.message,
    super.requestedAt,
    required super.status,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id'] ?? 0,
      requesterId: json['requesterId'] ?? 0,
      requesterUsername: json['requesterUsername'] ?? '',
      requesterName: json['requesterName'],
      requesterProfilePicture: json['requesterProfilePicture'],
      message: json['message'],
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : null,
      status: friendshipStatusFromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterUsername': requesterUsername,
      'requesterName': requesterName,
      'requesterProfilePicture': requesterProfilePicture,
      'message': message,
      'requestedAt': requestedAt?.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}
