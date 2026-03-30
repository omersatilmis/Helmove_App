import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_user_entity.dart';
import '../repositories/friendship_repository.dart';

class GetFriendsUseCase
    implements UseCase<List<FriendUserEntity>, GetFriendsParams> {
  final FriendshipRepository repository;

  GetFriendsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FriendUserEntity>>> call(
    GetFriendsParams params,
  ) async {
    return repository.getFriends(params.userId);
  }
}

class GetFriendsParams extends Equatable {
  final int userId;

  const GetFriendsParams({required this.userId});

  @override
  List<Object?> get props => [userId];
}
