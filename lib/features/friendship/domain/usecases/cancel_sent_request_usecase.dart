import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friendship_repository.dart';

class CancelSentRequestUseCase
    implements UseCase<FriendshipEntity, CancelSentRequestParams> {
  final FriendshipRepository repository;

  CancelSentRequestUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    CancelSentRequestParams params,
  ) async {
    return repository.cancelSentRequest(params.friendshipId);
  }
}

class CancelSentRequestParams extends Equatable {
  final int friendshipId;

  const CancelSentRequestParams({required this.friendshipId});

  @override
  List<Object?> get props => [friendshipId];
}
