import 'package:helmove/core/network/network_module.dart';
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
    super.userFirstName,
    super.userLastName,
    super.userProfileImage,
    required super.createdAt,
    super.likeCount,
    super.commentCount,
    super.isLiked,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userJson = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : <String, dynamic>{};
    final firstName = _pickString([userJson['firstName'], json['firstName']]);
    final lastName = _pickString([userJson['lastName'], json['lastName']]);
    final fullName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();

    return PostModel(
      id: _toInt(json['id']),
      type: _toInt(json['type']),
      text: _pickString([json['text'], json['description']]),
      mediaUrl: _pickNullableString([json['mediaUrl'], json['media']]),
      thumbnailUrl: _pickNullableString([
        json['thumbnailUrl'],
        json['thumbnail'],
      ]),
      visibility: _toInt(json['visibility']),
      userId: _toInt(userJson['id'] ?? json['userId']),
      username: _pickString([userJson['username'], json['username'], fullName]),
      userFirstName: firstName.isEmpty ? null : firstName,
      userLastName: lastName.isEmpty ? null : lastName,
      userProfileImage: NetworkModule.resolveImageUrl(
        _pickNullableString([
          userJson['profilePictureUrl'],
          userJson['avatarUrl'],
          json['userProfileImage'],
          json['profilePictureUrl'],
        ]),
      ),
      createdAt: _parseDateTime(json['createdAt']),
      likeCount: _toInt(json['likeCount'] ?? json['likesCount']),
      commentCount: _toInt(json['commentCount'] ?? json['commentsCount']),
      isLiked: _parseBool(
        json['isLiked'] ?? json['isLikedByMe'] ?? json['likedByCurrentUser'],
      ),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
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
    return {
      'id': id,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'visibility': visibility,
      'userId': userId,
      'username': username,
      'userFirstName': userFirstName,
      'userLastName': userLastName,
      'userProfileImage': userProfileImage,
      'createdAt': createdAt.toIso8601String(),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
    };
  }
}
