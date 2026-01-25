import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friendship_repository.dart';

class RemoveFriendUseCase
    implements UseCase<FriendshipEntity, RemoveFriendParams> {
  final FriendshipRepository repository;

  RemoveFriendUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    RemoveFriendParams params,
  ) async {
    return await repository.removeFriend(params.friendId);
  }
}

class RemoveFriendParams extends Equatable {
  final int friendId;

  const RemoveFriendParams({required this.friendId});

  @override
  List<Object?> get props => [friendId];
}
