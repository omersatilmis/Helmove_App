import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/follow_user.dart';
import '../repositories/follow_repository.dart';

class GetFollowersParams {
  final int userId;
  final int page;
  final int pageSize;

  GetFollowersParams({required this.userId, this.page = 1, this.pageSize = 20});
}

class GetFollowersUseCase implements UseCase<List<FollowUser>, GetFollowersParams> {
  final FollowRepository repository;

  GetFollowersUseCase(this.repository);

  @override
  Future<Either<Failure, List<FollowUser>>> call(GetFollowersParams params) async {
    return await repository.getFollowers(params.userId, page: params.page, pageSize: params.pageSize);
  }
}
