import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/follow_repository.dart';

class FollowUnblockUserUseCase implements UseCase<bool, int> {
  final FollowRepository repository;

  FollowUnblockUserUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(int userId) async {
    return await repository.unblockUser(userId);
  }
}
