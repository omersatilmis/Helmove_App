import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/follow_repository.dart';

class FollowUserUseCase implements UseCase<bool, int> {
  final FollowRepository repository;

  FollowUserUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(int userId) async {
    return await repository.followUser(userId);
  }
}
