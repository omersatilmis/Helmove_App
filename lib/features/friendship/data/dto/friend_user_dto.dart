import 'package:helmove/core/network/network_module.dart';
import '../../domain/entities/friend_user_entity.dart';

class FriendUserModel extends FriendUserEntity {
  const FriendUserModel({
    required super.id,
    required super.userId,
    required super.username,
    super.firstName,
    super.lastName,
    super.profilePictureUrl,
    super.isOnline,
    super.lastSeen,
    super.friendsSince,
    super.city,
    super.bio,
  });

  factory FriendUserModel.fromJson(Map<String, dynamic> json) {
    // Profile/search endpoint'i 'id' döndürüyor, Friendship endpoint'i 'userId' döndürüyor
    // İkisini de destekleyelim
    final userIdValue = json['userId'] ?? json['id'] ?? 0;
    return FriendUserModel(
      id: json['id'] ?? 0,
      userId: userIdValue,
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      profilePictureUrl: NetworkModule.resolveImageUrl(json['profilePictureUrl']?.toString()),
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      friendsSince: json['friendsSince'] != null
          ? DateTime.parse(json['friendsSince'])
          : null,
      city: json['city'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'friendsSince': friendsSince?.toIso8601String(),
      'city': city,
      'bio': bio,
    };
  }
}
