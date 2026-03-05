import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_datasource.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource remoteDataSource;

  CommentRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<CommentEntity>>> getComments({
    required int contentId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getComments(
        contentId: contentId,
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required int contentId,
    required String text,
  }) async {
    try {
      final result = await remoteDataSource.addComment(
        contentId: contentId,
        text: text,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(int commentId) async {
    try {
      await remoteDataSource.deleteComment(commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
