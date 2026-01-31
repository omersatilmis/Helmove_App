/// Jot visibility enum
enum JotVisibility { public, friendsOnly, private_ }

/// Jot type enum
enum JotType { text, image, video }

class JotEntity {
  final int id;
  final int userId;
  final JotType type;
  final String? text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final JotVisibility visibility;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // User info (if returned with jot)
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? userProfilePictureUrl;
  final String? bikeModel;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  const JotEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.visibility,
    this.createdAt,
    this.updatedAt,
    this.username,
    this.firstName,
    this.lastName,
    this.userProfilePictureUrl,
    this.bikeModel,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });
}
