import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/privacy_settings_entity.dart';

abstract class SettingsRepository {
  Future<Either<Failure, void>> updatePrivacy(PrivacySettingsEntity settings);
  Future<Either<Failure, void>> updateUnits();
  Future<Either<Failure, void>> updateMap();
  Future<Either<Failure, void>> updateAudio();
}
