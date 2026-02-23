import 'package:dartz/dartz.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/privacy_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/privacy_settings_model.dart';
import '../../../intercom/domain/intercom_engine.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;
  final IntercomEngine intercomEngine;

  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.intercomEngine,
  });

  @override
  Future<Either<Failure, void>> updatePrivacy(
    PrivacySettingsEntity settings,
  ) async {
    try {
      final model = PrivacySettingsModel(
        ghostMode: settings.ghostMode,
        locationPrivacy: settings.locationPrivacy,
        showProfileToOthers: settings.showProfileToOthers,
      );
      return Right(await remoteDataSource.updatePrivacy(model));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateUnits() async {
    try {
      return Right(await remoteDataSource.updateUnits());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMap() async {
    try {
      return Right(await remoteDataSource.updateMap());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateAudio() async {
    try {
      await remoteDataSource.updateAudio();
      // Notify engine immediately for real-time changes (e.g. Noise Suppression)
      await intercomEngine.onAudioSettingsChanged();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
