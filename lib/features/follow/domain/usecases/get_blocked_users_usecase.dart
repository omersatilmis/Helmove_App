import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/follow_user.dart';
import '../repositories/follow_repository.dart';

class GetBlockedUsersUseCase implements UseCase<List<FollowUser>, NoParams> {
  final FollowRepository repository;

  GetBlockedUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<FollowUser>>> call(NoParams params) async {
    return await repository.getBlockedUsers();
  }
}
