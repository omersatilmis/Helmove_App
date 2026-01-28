import '../../domain/entities/jot_entity.dart';

/// Request model for creating a new Jot
class CreateJotRequest {
  final int type;
  final String? text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int visibility;

  const CreateJotRequest({
    required this.type,
    this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.visibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'visibility': visibility,
    };
  }

  factory CreateJotRequest.fromEntity({
    required JotType type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    required JotVisibility visibility,
  }) {
    return CreateJotRequest(
      type: type.index,
      text: text,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      visibility: visibility.index,
    );
  }
}

/// Response model for Jot data from API
class JotModel extends JotEntity {
  const JotModel({
    required super.id,
    required super.userId,
    required super.type,
    super.text,
    super.mediaUrl,
    super.thumbnailUrl,
    required super.visibility,
    super.createdAt,
    super.updatedAt,
    super.username,
    super.userProfilePictureUrl,
  });

  factory JotModel.fromJson(Map<String, dynamic> json) {
    return JotModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      type: _parseJotType(json['type']),
      text: json['text'],
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      visibility: _parseVisibility(json['visibility']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      username: json['username'],
      userProfilePictureUrl: json['userProfilePictureUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'visibility': visibility.index,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'username': username,
      'userProfilePictureUrl': userProfilePictureUrl,
    };
  }

  static JotType _parseJotType(dynamic value) {
    if (value == null) return JotType.text;
    if (value is int) {
      return JotType.values.length > value
          ? JotType.values[value]
          : JotType.text;
    }
    return JotType.text;
  }

  static JotVisibility _parseVisibility(dynamic value) {
    if (value == null) return JotVisibility.public;
    if (value is int) {
      return JotVisibility.values.length > value
          ? JotVisibility.values[value]
          : JotVisibility.public;
    }
    return JotVisibility.public;
  }
}
