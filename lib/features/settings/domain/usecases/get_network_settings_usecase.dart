import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/network_settings_model.dart';
import '../repositories/settings_repository.dart';

class GetNetworkSettingsUseCase
    implements UseCase<NetworkSettingsModel, NoParams> {
  final SettingsRepository repository;

  GetNetworkSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, NetworkSettingsModel>> call(NoParams params) async {
    return await repository.getNetworkSettings();
  }
}
