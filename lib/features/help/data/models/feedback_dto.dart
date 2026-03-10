import '../../../../core/constants/feedback_enums.dart';
import '../../domain/entities/feedback_entity.dart';

class FeedbackDto {
  final int? id;
  final String? userId;
  final int category;
  final String title;
  final String content;
  final int status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FeedbackDto({
    this.id,
    this.userId,
    required this.category,
    required this.title,
    required this.content,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory FeedbackDto.fromJson(Map<String, dynamic> json) {
    return FeedbackDto(
      id: json['id'] as int?,
      userId: json['userId'] as String?,
      category: json['category'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      status: json['status'] as int,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'category': category,
      'title': title,
      'content': content,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  FeedbackEntity toEntity() {
    return FeedbackEntity(
      id: id,
      userId: userId,
      category: FeedbackCategory.fromValue(category),
      title: title,
      content: content,
      status: FeedbackStatus.fromValue(status),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
