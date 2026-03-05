import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/conditional_fetch_result.dart';
import '../../../../../core/models/paged_result.dart';
import '../entities/post_entity.dart';

abstract class PostRepository {
  Future<Either<Failure, PostEntity>> createPost({
    required int type,
    required String text,
    String? mediaUrl,
    String? thumbnailUrl,
    required int visibility,
  });

  Future<Either<Failure, ConditionalFetchResult<PagedResult<PostEntity>>>>
      getFeed({
    int page = 1,
    int limit = 10,
    String? ifNoneMatch,
  });

  Future<Either<Failure, PagedResult<PostEntity>>> getUserPosts({
    required int userId,
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, void>> deletePost(int id);

  Future<Either<Failure, void>> likePost(int id);
  Future<Either<Failure, void>> unlikePost(int id);
}
