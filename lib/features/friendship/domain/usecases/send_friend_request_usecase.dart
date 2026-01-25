import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friendship_repository.dart';

class SendFriendRequestUseCase
    implements UseCase<FriendshipEntity, SendFriendRequestParams> {
  final FriendshipRepository repository;

  SendFriendRequestUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    SendFriendRequestParams params,
  ) async {
    return await repository.sendFriendRequest(
      params.targetUserId,
      params.message,
    );
  }
}

class SendFriendRequestParams extends Equatable {
  final int targetUserId;
  final String message;

  const SendFriendRequestParams({
    required this.targetUserId,
    required this.message,
  });

  @override
  List<Object?> get props => [targetUserId, message];
}
