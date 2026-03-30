import '../../domain/entities/friendship_entity.dart';
import '../../domain/entities/friendship_status.dart';

class FriendshipModel extends FriendshipEntity {
  const FriendshipModel({
    required super.friendshipId,
    required super.status,
    super.actionDate,
    super.message,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      friendshipId: json['friendshipId'] ?? 0,
      status: friendshipStatusFromString(json['status']),
      actionDate: json['actionDate'] != null
          ? DateTime.tryParse(json['actionDate'].toString())
          : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendshipId': friendshipId,
      'status': status
          .toString()
          .split('.')
          .last, // or specific string if API requires
      'actionDate': actionDate?.toIso8601String(),
      'message': message,
    };
  }
}
