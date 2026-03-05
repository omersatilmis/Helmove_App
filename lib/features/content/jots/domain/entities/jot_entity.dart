import 'package:equatable/equatable.dart';

/// Jot visibility enum
enum JotVisibility { public, friendsOnly, private_ }

/// Jot type enum
enum JotType { text, image, video }

class JotEntity extends Equatable {
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

  JotEntity copyWith({
    int? id,
    int? userId,
    JotType? type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    JotVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? username,
    String? firstName,
    String? lastName,
    String? userProfilePictureUrl,
    String? bikeModel,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return JotEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userProfilePictureUrl:
          userProfilePictureUrl ?? this.userProfilePictureUrl,
      bikeModel: bikeModel ?? this.bikeModel,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    text,
    mediaUrl,
    thumbnailUrl,
    visibility,
    createdAt,
    updatedAt,
    username,
    firstName,
    lastName,
    userProfilePictureUrl,
    bikeModel,
    likeCount,
    commentCount,
    isLiked,
  ];
}
