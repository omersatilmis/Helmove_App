import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/jot_entity.dart';
import '../repositories/jots_repository.dart';
import '../../../../../core/models/paged_result.dart';

class GetUserJotsParams {
  final int userId;
  final int page;
  final int limit;

  const GetUserJotsParams({
    required this.userId,
    this.page = 1,
    this.limit = 10,
  });
}

class GetUserJotsUseCase
    implements UseCase<PagedResult<JotEntity>, GetUserJotsParams> {
  final JotsRepository repository;

  GetUserJotsUseCase(this.repository);

  @override
  Future<Either<Failure, PagedResult<JotEntity>>> call(
    GetUserJotsParams params,
  ) async {
    return await repository.getUserJots(
      params.userId,
      page: params.page,
      limit: params.limit,
    );
  }
}
