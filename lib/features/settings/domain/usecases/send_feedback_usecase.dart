import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/feedback_entity.dart';
import '../repositories/feedback_repository.dart';

class SendFeedbackUseCase implements UseCase<void, FeedbackEntity> {
  final FeedbackRepository repository;

  SendFeedbackUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(FeedbackEntity params) async {
    return await repository.sendFeedback(params);
  }
}
