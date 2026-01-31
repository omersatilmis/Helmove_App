import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class LikePostParams {
  final int postId;
  final bool isLiked;

  const LikePostParams({required this.postId, required this.isLiked});
}

class LikePostUseCase implements UseCase<void, LikePostParams> {
  final PostRepository repository;

  LikePostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LikePostParams params) async {
    if (params.isLiked) {
      return await repository.likePost(params.postId);
    } else {
      return await repository.unlikePost(params.postId);
    }
  }
}
