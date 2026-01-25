import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friendship_repository.dart';

class RejectFriendRequestUseCase
    implements UseCase<FriendshipEntity, RejectFriendRequestParams> {
  final FriendshipRepository repository;

  RejectFriendRequestUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    RejectFriendRequestParams params,
  ) async {
    return await repository.rejectFriendRequest(params.friendshipId);
  }
}

class RejectFriendRequestParams extends Equatable {
  final int friendshipId;

  const RejectFriendRequestParams({required this.friendshipId});

  @override
  List<Object?> get props => [friendshipId];
}
