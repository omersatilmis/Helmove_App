import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/error_handler.dart';
import '../../../friendship/domain/entities/friend_user_entity.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../../../../core/models/paged_result.dart';
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
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.getErrorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, PagedResult<PostEntity>>> getExploreContent({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await remoteDataSource.getExploreContent(
        page: page,
        limit: limit,
      );
      return Right(PagedResult(items: result.items, metadata: result.metadata));
    } catch (e) {
      return Left(ServerFailure(ErrorHandler.getErrorMessage(e)));
    }
  }
}
