import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/models/paged_result.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../repositories/discover_repository.dart';

class GetExploreUseCase
    implements UseCase<PagedResult<PostEntity>, GetExploreParams> {
  final DiscoverRepository repository;

  GetExploreUseCase(this.repository);

  @override
  Future<Either<Failure, PagedResult<PostEntity>>> call(
    GetExploreParams params,
  ) {
    return repository.getExploreContent(
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetExploreParams extends Equatable {
  final int page;
  final int limit;

  const GetExploreParams({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}
