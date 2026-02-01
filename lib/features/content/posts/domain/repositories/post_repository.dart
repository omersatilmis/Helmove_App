import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/post_entity.dart';

abstract class PostRepository {
  Future<Either<Failure, PostEntity>> createPost({
    required int type,
    required String text,
    String? mediaUrl,
    String? thumbnailUrl,
    required int visibility,
  });

  Future<Either<Failure, List<PostEntity>>> getFeed({
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, List<PostEntity>>> getUserPosts({
    required int userId,
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, void>> deletePost(int id);

  Future<Either<Failure, void>> likePost(int id);
  Future<Either<Failure, void>> unlikePost(int id);
}
