import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetUserPostsUseCase
    implements UseCase<List<PostEntity>, GetUserPostsParams> {
  final PostRepository repository;

  GetUserPostsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(GetUserPostsParams params) {
    return repository.getUserPosts(
      userId: params.userId,
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetUserPostsParams extends Equatable {
  final int userId;
  final int page;
  final int limit;

  const GetUserPostsParams({
    required this.userId,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object> get props => [userId, page, limit];
}
