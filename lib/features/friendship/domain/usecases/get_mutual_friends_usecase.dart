import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_user_entity.dart';
import '../repositories/friendship_repository.dart';

class GetMutualFriendsUseCase
    implements UseCase<List<FriendUserEntity>, GetMutualFriendsParams> {
  final FriendshipRepository repository;

  GetMutualFriendsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FriendUserEntity>>> call(
    GetMutualFriendsParams params,
  ) async {
    return await repository.getMutualFriends(params.targetUserId);
  }
}

class GetMutualFriendsParams extends Equatable {
  final int targetUserId;

  const GetMutualFriendsParams({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}
