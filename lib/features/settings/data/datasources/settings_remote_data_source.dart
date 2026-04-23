import 'package:dio/dio.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/error_handler.dart';
import '../models/privacy_settings_model.dart';
import '../models/audio_settings_model.dart';
import '../models/network_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<void> updatePrivacy(PrivacySettingsModel settings);
  Future<void> updateUnits();
  Future<void> updateMap();
  Future<AudioSettingsModel> getAudioSettings();
  Future<void> updateAudio(AudioSettingsModel settings);
  Future<NetworkSettingsModel> getNetworkSettings();
  Future<void> updateNetwork(NetworkSettingsModel settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final Dio client;

  SettingsRemoteDataSourceImpl({required this.client});

  Map<String, dynamic> _extractPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (inner is Map<String, dynamic>) {
        return inner;
      }
      return raw;
    }
    throw ServerException('Beklenmeyen sunucu yaniti');
  }

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
  Future<AudioSettingsModel> getAudioSettings() async {
    try {
      final response = await client.get('/api/settings/audio');
      if (response.statusCode == 200) {
        final data = _extractPayload(response.data);
        return AudioSettingsModel.fromJson(data);
      }
      throw ServerException('Ses ayarları alınamadı');
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  @override
  Future<void> updateAudio(AudioSettingsModel settings) async {
    try {
      final response = await client.put(
        '/api/settings/audio',
        data: settings.toJson(),
      );
      if (response.statusCode != 200) {
        throw ServerException('Ses ayarları güncellenemedi');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  @override
  Future<NetworkSettingsModel> getNetworkSettings() async {
    try {
      final response = await client.get('/api/settings/network');
      if (response.statusCode == 200) {
        final data = _extractPayload(response.data);
        return NetworkSettingsModel.fromJson(data);
      }
      throw ServerException('Ağ ayarları alınamadı');
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  @override
  Future<void> updateNetwork(NetworkSettingsModel settings) async {
    try {
      final response = await client.put(
        '/api/settings/network',
        data: settings.toJson(),
      );
      if (response.statusCode != 200) {
        throw ServerException('Ağ ayarları güncellenemedi');
      }
    } on DioException catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }
}
