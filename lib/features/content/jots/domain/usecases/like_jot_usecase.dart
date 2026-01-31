import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/jots_repository.dart';

class LikeJotParams {
  final int id;
  final bool isLiked;

  const LikeJotParams({required this.id, required this.isLiked});
}

class LikeJotUseCase implements UseCase<void, LikeJotParams> {
  final JotsRepository repository;

  LikeJotUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LikeJotParams params) {
    if (params.isLiked) {
      return repository.unlikeJot(params.id);
    } else {
      return repository.likeJot(params.id);
    }
  }
}
