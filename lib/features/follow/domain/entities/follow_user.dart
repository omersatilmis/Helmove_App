import 'package:equatable/equatable.dart';

class FollowUser extends Equatable {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final bool isFollowing;
  final bool isFollower;

  const FollowUser({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    this.isFollowing = false,
    this.isFollower = false,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  FollowUser copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
    bool? isFollowing,
    bool? isFollower,
  }) {
    return FollowUser(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        firstName,
        lastName,
        profilePictureUrl,
        isFollowing,
        isFollower,
      ];
}
