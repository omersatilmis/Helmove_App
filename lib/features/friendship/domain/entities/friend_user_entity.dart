class FriendUserEntity {
  final int id; // Friendship ID usually, but based on API response
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? friendsSince;
  final String? city;
  final String? bio;

  const FriendUserEntity({
    required this.id,
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    this.isOnline = false,
    this.lastSeen,
    this.friendsSince,
    this.city,
    this.bio,
  });

  String get fullName {
    if (firstName == null && lastName == null) return username;
    return "${firstName ?? ''} ${lastName ?? ''}".trim();
  }
}
