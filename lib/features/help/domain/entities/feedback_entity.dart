import 'package:equatable/equatable.dart';
import '../../../../core/constants/feedback_enums.dart';

class FeedbackEntity extends Equatable {
  final int? id;
  final String? userId;
  final FeedbackCategory category;
  final String title;
  final String content;
  final FeedbackStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeedbackEntity({
    this.id,
    this.userId,
    required this.category,
    required this.title,
    required this.content,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        title,
        content,
        status,
        createdAt,
        updatedAt,
      ];
}
