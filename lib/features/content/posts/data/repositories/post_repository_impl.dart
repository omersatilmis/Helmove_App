import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/models/paged_result.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';
import '../models/create_post_request.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PostEntity>> createPost({
    required int type,
    required String text,
    String? mediaUrl,
    String? thumbnailUrl,
    required int visibility,
  }) async {
    try {
      final request = CreatePostRequest(
        type: type,
        text: text,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        visibility: visibility,
      );
      final result = await remoteDataSource.createPost(request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<PostEntity>>> getFeed({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getFeed(page: page, limit: limit);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<PostEntity>>> getUserPosts({
    required int userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getUserPosts(
        userId: userId,
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(int id) async {
    try {
      await remoteDataSource.deletePost(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> likePost(int id) async {
    try {
      await remoteDataSource.likePost(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unlikePost(int id) async {
    try {
      await remoteDataSource.unlikePost(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
