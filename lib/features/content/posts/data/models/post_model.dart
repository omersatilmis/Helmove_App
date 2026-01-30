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
      id: json['id'] as int,
      type: json['type'] as int,
      text: json['text'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      visibility: json['visibility'] as int,
      userId: json['userId'] as int,
      username: json['username'] ?? '',
      userProfileImage: json['userProfileImage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
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
