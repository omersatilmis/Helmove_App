import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_user_entity.dart';
import '../repositories/friendship_repository.dart';

class SearchFriendsUseCase
    implements UseCase<List<FriendUserEntity>, SearchFriendsParams> {
  final FriendshipRepository repository;

  SearchFriendsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FriendUserEntity>>> call(
    SearchFriendsParams params,
  ) async {
    return await repository.searchFriends(params.query);
  }
}

class SearchFriendsParams extends Equatable {
  final String query;

  const SearchFriendsParams({required this.query});

  @override
  List<Object?> get props => [query];
}
