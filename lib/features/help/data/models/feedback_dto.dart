import '../../../../core/constants/feedback_enums.dart';
import '../../domain/entities/feedback_entity.dart';

const _categoryNames = {
  0: 'General',
  1: 'BugReport',
  2: 'FeatureRequest',
  3: 'UIImprovement',
  4: 'Performance',
  5: 'Security',
  6: 'Other',
};

const _categoryValues = {
  'General': 0,
  'BugReport': 1,
  'FeatureRequest': 2,
  'UIImprovement': 3,
  'Performance': 4,
  'Security': 5,
  'Other': 6,
};

const _statusValues = {
  'New': 0,
  'Read': 1,
  'InProgress': 2,
  'Completed': 3,
  'WontFix': 4,
};

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
    final rawCategory = json['category'];
    final categoryInt = rawCategory is int
        ? rawCategory
        : _categoryValues[rawCategory as String?] ?? 6;

    final rawStatus = json['status'];
    final statusInt = rawStatus is int
        ? rawStatus
        : _statusValues[rawStatus as String?] ?? 0;

    return FeedbackDto(
      id: json['id'] as int?,
      userId: json['userId']?.toString(),
      category: categoryInt,
      title: json['title'] as String,
      content: (json['description'] ?? json['content'] ?? '') as String,
      status: statusInt,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': _categoryNames[category] ?? 'Other',
      'title': title,
      'description': content,
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
