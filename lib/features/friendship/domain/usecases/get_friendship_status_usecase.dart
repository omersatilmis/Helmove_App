import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_status.dart';
import '../repositories/friendship_repository.dart';

class GetFriendshipStatusUseCase
    implements UseCase<FriendshipStatus, GetFriendshipStatusParams> {
  final FriendshipRepository repository;

  GetFriendshipStatusUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipStatus>> call(
    GetFriendshipStatusParams params,
  ) async {
    return await repository.getFriendshipStatus(params.targetUserId);
  }
}

class GetFriendshipStatusParams extends Equatable {
  final int targetUserId;

  const GetFriendshipStatusParams({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}
