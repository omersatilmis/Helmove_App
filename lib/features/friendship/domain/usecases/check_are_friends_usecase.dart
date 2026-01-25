import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/friendship_repository.dart';

class CheckAreFriendsUseCase implements UseCase<bool, CheckAreFriendsParams> {
  final FriendshipRepository repository;

  CheckAreFriendsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckAreFriendsParams params) async {
    return await repository.checkAreFriends(params.targetUserId);
  }
}

class CheckAreFriendsParams extends Equatable {
  final int targetUserId;

  const CheckAreFriendsParams({required this.targetUserId});

  @override
  List<Object?> get props => [targetUserId];
}
