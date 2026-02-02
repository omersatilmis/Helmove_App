import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/models/paged_result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetPostsFeedUseCase
    implements UseCase<PagedResult<PostEntity>, GetFeedParams> {
  final PostRepository repository;

  GetPostsFeedUseCase(this.repository);

  @override
  Future<Either<Failure, PagedResult<PostEntity>>> call(GetFeedParams params) {
    return repository.getFeed(page: params.page, limit: params.limit);
  }
}

class GetFeedParams extends Equatable {
  final int page;
  final int limit;

  const GetFeedParams({this.page = 1, this.limit = 10});

  @override
  List<Object> get props => [page, limit];
}
