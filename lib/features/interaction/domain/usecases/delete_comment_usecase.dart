import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/repositories/comment_repository.dart';

class DeleteCommentUseCase implements UseCase<void, DeleteCommentParams> {
  final CommentRepository repository;

  DeleteCommentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCommentParams params) {
    return repository.deleteComment(params.commentId);
  }
}

class DeleteCommentParams extends Equatable {
  final int commentId;

  const DeleteCommentParams({required this.commentId});

  @override
  List<Object?> get props => [commentId];
}
