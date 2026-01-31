import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';

class AddCommentUseCase implements UseCase<CommentEntity, AddCommentParams> {
  final CommentRepository repository;

  AddCommentUseCase(this.repository);

  @override
  Future<Either<Failure, CommentEntity>> call(AddCommentParams params) {
    return repository.addComment(
      contentId: params.contentId,
      text: params.text,
    );
  }
}

class AddCommentParams extends Equatable {
  final int contentId;
  final String text;

  const AddCommentParams({required this.contentId, required this.text});

  @override
  List<Object?> get props => [contentId, text];
}
