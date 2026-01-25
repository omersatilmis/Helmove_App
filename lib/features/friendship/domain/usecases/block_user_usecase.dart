import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friendship_repository.dart';

class BlockUserUseCase implements UseCase<FriendshipEntity, BlockUserParams> {
  final FriendshipRepository repository;

  BlockUserUseCase(this.repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(BlockUserParams params) async {
    return await repository.blockUser(params.targetUserId);
  }
}

class BlockUserParams extends Equatable {
  final int targetUserId;

  const BlockUserParams({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}
