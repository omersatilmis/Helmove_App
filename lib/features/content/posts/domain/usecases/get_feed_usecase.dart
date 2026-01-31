import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetPostsFeedUseCase implements UseCase<List<PostEntity>, GetFeedParams> {
  final PostRepository repository;

  GetPostsFeedUseCase(this.repository);

  @override
  Future<Either<Failure, List<PostEntity>>> call(GetFeedParams params) {
    return repository.getFeed(page: params.page);
  }
}

class GetFeedParams extends Equatable {
  final int page;

  const GetFeedParams({this.page = 1});

  @override
  List<Object> get props => [page];
}
