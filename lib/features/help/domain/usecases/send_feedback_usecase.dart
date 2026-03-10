import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/feedback_entity.dart';
import '../repositories/help_repository.dart';

class SendFeedbackUseCase implements UseCase<FeedbackEntity, FeedbackEntity> {
  final HelpRepository repository;

  SendFeedbackUseCase(this.repository);

  @override
  Future<Either<Failure, FeedbackEntity>> call(FeedbackEntity params) async {
    try {
      final result = await repository.sendFeedback(params);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
