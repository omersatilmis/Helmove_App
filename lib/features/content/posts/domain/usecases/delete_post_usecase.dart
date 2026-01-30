import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/post_repository.dart';

class DeletePostUseCase implements UseCase<void, DeletePostParams> {
  final PostRepository repository;

  DeletePostUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePostParams params) {
    return repository.deletePost(params.id);
  }
}

class DeletePostParams extends Equatable {
  final int id;

  const DeletePostParams({required this.id});

  @override
  List<Object> get props => [id];
}
