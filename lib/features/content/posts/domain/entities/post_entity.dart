import 'package:equatable/equatable.dart';

class PostEntity extends Equatable {
  final int id;
  final int type;
  final String text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int visibility;
  final int userId;
  final String username;
  final String? userProfileImage;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  const PostEntity({
    required this.id,
    required this.type,
    required this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.visibility,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    text,
    mediaUrl,
    thumbnailUrl,
    visibility,
    userId,
    username,
    userProfileImage,
    createdAt,
    likeCount,
    commentCount,
    isLiked,
  ];
}
