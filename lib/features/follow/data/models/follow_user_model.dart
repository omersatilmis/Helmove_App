import 'package:helmove/core/network/network_module.dart';
import '../../domain/entities/follow_user.dart';

class FollowUserModel extends FollowUser {
  const FollowUserModel({
    required super.id,
    required super.username,
    super.firstName,
    super.lastName,
    super.profilePictureUrl,
    super.isFollowing = false,
    super.isFollower = false,
  });

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    final dynamic idValue = json['id'] ?? json['userId'] ?? json['targetUserId'];
    final dynamic usernameValue =
        json['username'] ?? json['userName'] ?? json['user_name'];
    final bool? parsedIsFollower = _asNullableBool(
      json['isFollower'] ??
          json['IsFollower'] ??
          json['followsMe'] ??
          json['FollowsMe'],
    );
    final bool? parsedIsFollowing = _asNullableBool(
      json['isFollowing'] ??
          json['IsFollowing'] ??
          json['isFollowedByCurrentUser'] ??
          json['IsFollowedByCurrentUser'] ??
          json['followedByMe'] ??
          json['FollowedByMe'],
    );

    return FollowUserModel(
      id: _asInt(idValue),
      username: _asString(usernameValue),
      firstName: _asNullableString(json['firstName'] ?? json['first_name']),
      lastName: _asNullableString(json['lastName'] ?? json['last_name']),
      profilePictureUrl: NetworkModule.resolveImageUrl(
        _asNullableString(
          json['profilePictureUrl'] ??
              json['profileImageUrl'] ??
              json['avatarUrl'] ??
              json['profile_picture_url'],
        ),
      ),
      isFollowing: parsedIsFollowing ?? false,
      isFollower: parsedIsFollower ?? false,
    );
  }

  @override
  FollowUserModel copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
    bool? isFollowing,
    bool? isFollower,
  }) {
    return FollowUserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
      'isFollowing': isFollowing,
      'isFollower': isFollower,
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Invalid follow user id');
  }

  static String _asString(dynamic value) {
    if (value is String) return value;
    throw const FormatException('Invalid follow username');
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static bool? _asNullableBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}
