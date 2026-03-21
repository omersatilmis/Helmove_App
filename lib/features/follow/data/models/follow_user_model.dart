import '../../domain/entities/follow_user.dart';

class FollowUserModel extends FollowUser {
  const FollowUserModel({
    required super.id,
    required super.username,
    super.firstName,
    super.lastName,
    super.profilePictureUrl,
    super.isFollowingBack,
    super.isFollowing = false,
  });

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    return FollowUserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      isFollowingBack: json['isFollowingBack'] as bool?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
      'isFollowingBack': isFollowingBack,
      'isFollowing': isFollowing,
    };
  }
}
