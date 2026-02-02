import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

class UpdateAudioUseCase implements UseCase<void, NoParams> {
  final SettingsRepository repository;

  UpdateAudioUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.updateAudio();
  }
}
