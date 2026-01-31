import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.text,
    required super.userId,
    required super.username,
    super.userAvatar,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    var user = json['user'];
    if (user == null && json['User'] != null) {
      user = json['User'];
    }

    // cast details
    final userData = user is Map<String, dynamic> ? user : <String, dynamic>{};

    return CommentModel(
      id: json['id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      userId: userData['id'] as int? ?? userData['Id'] as int? ?? 0,
      username:
          userData['username'] as String? ??
          userData['Username'] as String? ??
          'Unknown User',
      userAvatar:
          userData['profilePictureUrl'] as String? ??
          userData['ProfilePictureUrl'] as String? ??
          userData['userProfileImage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}
