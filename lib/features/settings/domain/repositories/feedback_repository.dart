import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/feedback_entity.dart';

abstract class FeedbackRepository {
  Future<Either<Failure, void>> sendFeedback(FeedbackEntity feedback);
}
