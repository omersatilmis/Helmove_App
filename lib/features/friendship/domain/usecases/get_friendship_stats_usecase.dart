import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_stats_entity.dart';
import '../repositories/friendship_repository.dart';

class GetFriendshipStatsUseCase
    implements UseCase<FriendStatsEntity, GetFriendshipStatsParams> {
  final FriendshipRepository repository;

  GetFriendshipStatsUseCase(this.repository);

  @override
  Future<Either<Failure, FriendStatsEntity>> call(
    GetFriendshipStatsParams params,
  ) async {
    return await repository.getFriendshipStats(userId: params.userId);
  }
}

class GetFriendshipStatsParams {
  final int? userId; // Null ise current user
  const GetFriendshipStatsParams({this.userId});
}
