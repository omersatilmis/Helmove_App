import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../friendship/domain/entities/friend_user_entity.dart';
import '../datasources/discover_remote_datasource.dart';
import '../../domain/repositories/discover_repository.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  final DiscoverRemoteDataSource remoteDataSource;

  DiscoverRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<FriendUserEntity>>> searchUsers(
    String query, {
    String? city,
    int limit = 20,
  }) async {
    try {
      final result = await remoteDataSource.searchUsers(
        query,
        city: city,
        limit: limit,
      );
      // Map Model to Entity (Assuming FriendUserModel extends FriendUserEntity or is compatible)
      // If FriendUserModel extends FriendUserEntity, we can just cast or return as is.
      // Checking existing code, normally Model extends Entity.
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
