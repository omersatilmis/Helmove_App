import '../../domain/entities/feedback_entity.dart';

class FeedbackModel extends FeedbackEntity {
  const FeedbackModel({
    required super.message,
    required super.category,
    super.screenshot,
  });

  factory FeedbackModel.fromEntity(FeedbackEntity entity) {
    return FeedbackModel(
      message: entity.message,
      category: entity.category,
      screenshot: entity.screenshot,
    );
  }
}
