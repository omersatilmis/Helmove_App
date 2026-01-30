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

  PostEntity copyWith({
    int? id,
    int? type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    int? visibility,
    int? userId,
    String? username,
    String? userProfileImage,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return PostEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      visibility: visibility ?? this.visibility,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

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
