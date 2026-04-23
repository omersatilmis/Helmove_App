import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/network_settings_model.dart';
import '../repositories/settings_repository.dart';

class UpdateNetworkUseCase implements UseCase<void, NetworkSettingsModel> {
  final SettingsRepository repository;

  UpdateNetworkUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NetworkSettingsModel params) async {
    return await repository.updateNetwork(params);
  }
}
