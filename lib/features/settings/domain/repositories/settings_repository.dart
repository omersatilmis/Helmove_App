import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/privacy_settings_entity.dart';
import '../../data/models/audio_settings_model.dart';
import '../../data/models/network_settings_model.dart';

abstract class SettingsRepository {
  Future<Either<Failure, void>> updatePrivacy(PrivacySettingsEntity settings);
  Future<Either<Failure, void>> updateUnits();
  Future<Either<Failure, void>> updateMap();
  Future<Either<Failure, AudioSettingsModel>> getAudioSettings();
  Future<Either<Failure, void>> updateAudio(AudioSettingsModel settings);
  Future<Either<Failure, NetworkSettingsModel>> getNetworkSettings();
  Future<Either<Failure, void>> updateNetwork(NetworkSettingsModel settings);
}
