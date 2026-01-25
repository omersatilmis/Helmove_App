import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friendship_repository.dart';

class UnblockUserUseCase
    implements UseCase<FriendshipEntity, UnblockUserParams> {
  final FriendshipRepository repository;

  UnblockUserUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    UnblockUserParams params,
  ) async {
    return await repository.unblockUser(params.targetUserId);
  }
}

class UnblockUserParams extends Equatable {
  final int targetUserId;

  const UnblockUserParams({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}
