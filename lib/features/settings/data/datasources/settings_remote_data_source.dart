import 'package:dio/dio.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/error_handler.dart';
import '../models/privacy_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<void> updatePrivacy(PrivacySettingsModel settings);
  Future<void> updateUnits();
  Future<void> updateMap();
  Future<void> updateAudio();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final Dio client;

  SettingsRemoteDataSourceImpl({required this.client});

  @override
  Future<void> updatePrivacy(PrivacySettingsModel settings) async {
    try {
      final response = await client.put(
        '/api/settings/privacy',
        data: settings.toJson(),
      );

      if (response.statusCode != 200) {
        throw ServerException('Gizlilik ayarları güncellenemedi');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  @override
  Future<void> updateUnits() async {
    try {
      final response = await client.put('/api/settings/units');
      if (response.statusCode != 200) {
        throw ServerException('Birim ayarları güncellenemedi');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  @override
  Future<void> updateMap() async {
    try {
      final response = await client.put('/api/settings/map');
      if (response.statusCode != 200) {
        throw ServerException('Harita ayarları güncellenemedi');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  @override
  Future<void> updateAudio() async {
    try {
      final response = await client.put('/api/settings/audio');
      if (response.statusCode != 200) {
        throw ServerException('Ses ayarları güncellenemedi');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }
}
