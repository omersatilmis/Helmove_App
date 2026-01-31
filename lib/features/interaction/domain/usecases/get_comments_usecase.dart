import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';

class GetCommentsUseCase
    implements UseCase<List<CommentEntity>, GetCommentsParams> {
  final CommentRepository repository;

  GetCommentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CommentEntity>>> call(GetCommentsParams params) {
    return repository.getComments(
      contentId: params.contentId,
      page: params.page,
    );
  }
}

class GetCommentsParams extends Equatable {
  final int contentId;
  final int page;

  const GetCommentsParams({required this.contentId, this.page = 1});

  @override
  List<Object?> get props => [contentId, page];
}
