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
    final userObj = json['user'];
    final userData = userObj is Map
        ? Map<String, dynamic>.from(userObj)
        : <String, dynamic>{};

    final firstName = _pickString([
      userData['firstName'],
      json['firstName'],
    ]);
    final lastName = _pickString([
      userData['lastName'],
      json['lastName'],
    ]);
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();

    return CommentModel(
      id: _toInt(json['id']),
      text: _pickString([json['text'], json['comment']]),
      userId: _toInt(userData['id'] ?? json['userId']),
      username: _pickString([
        userData['username'],
        json['username'],
        fullName,
        'Misafir',
      ]),
      userAvatar: _pickNullableString([
        userData['profilePictureUrl'],
        userData['profileImageUrl'],
        userData['avatarUrl'],
        userData['avatar'],
        userData['picture'],
        json['userAvatar'],
        json['profilePictureUrl'],
        json['profileImageUrl'],
      ]),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _pickString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static String? _pickNullableString(List<dynamic> values) {
    final text = _pickString(values);
    return text.isEmpty ? null : text;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {'text': text};
  }
}
