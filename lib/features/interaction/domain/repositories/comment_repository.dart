import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/comment_entity.dart';

abstract class CommentRepository {
  Future<Either<Failure, List<CommentEntity>>> getComments({
    required int contentId,
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, CommentEntity>> addComment({
    required int contentId,
    required String text,
  });

  Future<Either<Failure, void>> deleteComment(int commentId);
}
