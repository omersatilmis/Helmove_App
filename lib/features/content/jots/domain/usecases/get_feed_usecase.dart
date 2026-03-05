import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/jot_entity.dart';
import '../repositories/jots_repository.dart';
import '../../../../../core/models/conditional_fetch_result.dart';
import '../../../../../core/models/paged_result.dart';

class GetFeedParams {
  final int page;
  final int limit;
  final String? ifNoneMatch;

  const GetFeedParams({this.page = 1, this.limit = 10, this.ifNoneMatch});
}

class GetJotsFeedUseCase
    implements
        UseCase<ConditionalFetchResult<PagedResult<JotEntity>>, GetFeedParams> {
  final JotsRepository repository;

  GetJotsFeedUseCase(this.repository);

  @override
  Future<Either<Failure, ConditionalFetchResult<PagedResult<JotEntity>>>> call(
    GetFeedParams params,
  ) async {
    return await repository.getFeed(
      page: params.page,
      limit: params.limit,
      ifNoneMatch: params.ifNoneMatch,
    );
  }
}
