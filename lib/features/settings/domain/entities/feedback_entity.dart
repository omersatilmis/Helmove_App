import 'dart:io';

class FeedbackEntity {
  final String message;
  final String category;
  final File? screenshot;

  const FeedbackEntity({
    required this.message,
    required this.category,
    this.screenshot,
  });
}
