import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

class UpdateMapUseCase implements UseCase<void, NoParams> {
  final SettingsRepository repository;

  UpdateMapUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.updateMap();
  }
}
