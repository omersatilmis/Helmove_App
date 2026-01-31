import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/jot_entity.dart';
import '../repositories/jots_repository.dart';

class GetFeedParams {
  final int page;

  const GetFeedParams({this.page = 1});
}

class GetJotsFeedUseCase implements UseCase<List<JotEntity>, GetFeedParams> {
  final JotsRepository repository;

  GetJotsFeedUseCase(this.repository);

  @override
  Future<Either<Failure, List<JotEntity>>> call(GetFeedParams params) async {
    return await repository.getFeed(page: params.page);
  }
}
