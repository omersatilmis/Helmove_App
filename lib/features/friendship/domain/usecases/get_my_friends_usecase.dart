import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_user_entity.dart';
import '../repositories/friendship_repository.dart';

class GetMyFriendsUseCase implements UseCase<List<FriendUserEntity>, NoParams> {
  final FriendshipRepository repository;

  GetMyFriendsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FriendUserEntity>>> call(NoParams params) async {
    return await repository.getMyFriends();
  }
}
