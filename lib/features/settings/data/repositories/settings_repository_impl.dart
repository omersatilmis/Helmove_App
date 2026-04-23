import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/privacy_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/privacy_settings_model.dart';
import '../models/audio_settings_model.dart';
import '../models/network_settings_model.dart';
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
  Future<Either<Failure, AudioSettingsModel>> getAudioSettings() async {
    try {
      final model = await remoteDataSource.getAudioSettings();
      final prefs = await SharedPreferences.getInstance();
      if (model.noiseCancellationEnabled != null) {
        await prefs.setBool(
          'audio_noise_suppression',
          model.noiseCancellationEnabled!,
        );
      }
      if (model.voiceNavigationEnabled != null) {
        await prefs.setBool(
          'voice_navigation_enabled',
          model.voiceNavigationEnabled!,
        );
      }
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateAudio(AudioSettingsModel settings) async {
    try {
      await remoteDataSource.updateAudio(settings);
      final prefs = await SharedPreferences.getInstance();
      if (settings.noiseCancellationEnabled != null) {
        await prefs.setBool(
          'audio_noise_suppression',
          settings.noiseCancellationEnabled!,
        );
      }
      if (settings.voiceNavigationEnabled != null) {
        await prefs.setBool(
          'voice_navigation_enabled',
          settings.voiceNavigationEnabled!,
        );
      }
      await intercomEngine.onAudioSettingsChanged();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, NetworkSettingsModel>> getNetworkSettings() async {
    try {
      final model = await remoteDataSource.getNetworkSettings();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wifi_only_download', model.wifiOnlyDownload);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateNetwork(
    NetworkSettingsModel settings,
  ) async {
    try {
      await remoteDataSource.updateNetwork(settings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wifi_only_download', settings.wifiOnlyDownload);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
