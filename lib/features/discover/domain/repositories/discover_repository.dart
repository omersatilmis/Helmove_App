import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../friendship/domain/entities/friend_user_entity.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../../../../core/models/paged_result.dart';

abstract class DiscoverRepository {
  Future<Either<Failure, List<FriendUserEntity>>> searchUsers(
    String query, {
    String? city,
    int limit = 20,
  });

  Future<Either<Failure, PagedResult<PostEntity>>> getExploreContent({
    int page = 1,
    int limit = 20,
  });
}
