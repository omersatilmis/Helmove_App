import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.type,
    required super.text,
    super.mediaUrl,
    super.thumbnailUrl,
    required super.visibility,
    required super.userId,
    required super.username,
    super.userProfileImage,
    required super.createdAt,
    super.likeCount,
    super.commentCount,
    super.isLiked,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      visibility: json['visibility'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: parseBool(json['isLiked'] ?? json['isLikedByMe']),
    );
  }

  static bool parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'visibility': visibility,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
    };
  }
}
