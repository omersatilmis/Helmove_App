import 'package:equatable/equatable.dart';

class FollowUser extends Equatable {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final bool? isFollowingBack;
  final bool isFollowing;

  const FollowUser({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    this.isFollowingBack,
    this.isFollowing = false,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  FollowUser copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
    bool? isFollowingBack,
    bool? isFollowing,
  }) {
    return FollowUser(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isFollowingBack: isFollowingBack ?? this.isFollowingBack,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        firstName,
        lastName,
        profilePictureUrl,
        isFollowingBack,
        isFollowing,
      ];
}
