import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/jot_entity.dart';
import '../repositories/jots_repository.dart';

class CreateJotParams {
  final JotType type;
  final String? text;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final JotVisibility visibility;

  const CreateJotParams({
    required this.type,
    this.text,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.visibility,
  });
}

class CreateJotUseCase implements UseCase<JotEntity, CreateJotParams> {
  final JotsRepository repository;

  CreateJotUseCase(this.repository);

  @override
  Future<Either<Failure, JotEntity>> call(CreateJotParams params) async {
    return await repository.createJot(
      type: params.type,
      text: params.text,
      mediaUrl: params.mediaUrl,
      thumbnailUrl: params.thumbnailUrl,
      visibility: params.visibility,
    );
  }
}
