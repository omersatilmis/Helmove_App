import 'package:dartz/dartz.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/feedback_entity.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_data_source.dart';
import '../models/feedback_model.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource remoteDataSource;

  FeedbackRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> sendFeedback(FeedbackEntity feedback) async {
    try {
      final model = FeedbackModel.fromEntity(feedback);
      await remoteDataSource.sendFeedback(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
