import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/jots_repository.dart';

class LikeJotUseCase implements UseCase<void, int> {
  final JotsRepository repository;

  LikeJotUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int params) {
    return repository.likeJot(params);
  }
}
