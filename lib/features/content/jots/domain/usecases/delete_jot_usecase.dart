import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/jots_repository.dart';

class DeleteJotParams {
  final int id;

  const DeleteJotParams({required this.id});
}

class DeleteJotUseCase implements UseCase<void, DeleteJotParams> {
  final JotsRepository repository;

  DeleteJotUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteJotParams params) async {
    return await repository.deleteJot(params.id);
  }
}
