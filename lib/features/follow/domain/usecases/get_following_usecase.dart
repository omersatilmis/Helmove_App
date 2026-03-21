import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/follow_user.dart';
import '../repositories/follow_repository.dart';

class GetFollowingParams {
  final int userId;
  final int page;
  final int pageSize;

  GetFollowingParams({required this.userId, this.page = 1, this.pageSize = 20});
}

class GetFollowingUseCase implements UseCase<List<FollowUser>, GetFollowingParams> {
  final FollowRepository repository;

  GetFollowingUseCase(this.repository);

  @override
  Future<Either<Failure, List<FollowUser>>> call(GetFollowingParams params) async {
    return await repository.getFollowing(params.userId, page: params.page, pageSize: params.pageSize);
  }
}
