import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_stats_entity.dart';
import '../repositories/friendship_repository.dart';

class GetFriendshipStatsUseCase
    implements UseCase<FriendStatsEntity, NoParams> {
  final FriendshipRepository repository;

  GetFriendshipStatsUseCase(this.repository);

  @override
  Future<Either<Failure, FriendStatsEntity>> call(NoParams params) async {
    return await repository.getFriendshipStats();
  }
}
