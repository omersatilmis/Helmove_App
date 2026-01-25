import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friendship_repository.dart';

class AcceptFriendRequestUseCase
    implements UseCase<FriendshipEntity, AcceptFriendRequestParams> {
  final FriendshipRepository repository;

  AcceptFriendRequestUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    AcceptFriendRequestParams params,
  ) async {
    return await repository.acceptFriendRequest(params.friendshipId);
  }
}

class AcceptFriendRequestParams extends Equatable {
  final int friendshipId;

  const AcceptFriendRequestParams({required this.friendshipId});

  @override
  List<Object?> get props => [friendshipId];
}
