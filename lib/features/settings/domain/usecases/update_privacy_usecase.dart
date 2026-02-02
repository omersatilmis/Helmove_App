import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/privacy_settings_entity.dart';
import '../repositories/settings_repository.dart';

class UpdatePrivacyUseCase implements UseCase<void, PrivacySettingsEntity> {
  final SettingsRepository repository;

  UpdatePrivacyUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(PrivacySettingsEntity params) async {
    return await repository.updatePrivacy(params);
  }
}
