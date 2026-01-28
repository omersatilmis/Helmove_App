import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/jot_entity.dart';
import '../repositories/jots_repository.dart';

class GetUserJotsParams {
  final int userId;
  final int page;

  const GetUserJotsParams({required this.userId, this.page = 1});
}

class GetUserJotsUseCase
    implements UseCase<List<JotEntity>, GetUserJotsParams> {
  final JotsRepository repository;

  GetUserJotsUseCase(this.repository);

  @override
  Future<Either<Failure, List<JotEntity>>> call(
    GetUserJotsParams params,
  ) async {
    return await repository.getUserJots(params.userId, page: params.page);
  }
}
