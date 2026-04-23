import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/audio_settings_model.dart';
import '../repositories/settings_repository.dart';

class GetAudioSettingsUseCase
    implements UseCase<AudioSettingsModel, NoParams> {
  final SettingsRepository repository;

  GetAudioSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, AudioSettingsModel>> call(NoParams params) async {
    return await repository.getAudioSettings();
  }
}
