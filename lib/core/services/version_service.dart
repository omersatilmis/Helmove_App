import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

class AppVersionData {
  final String minVersion;
  final String latestVersion;
  final String androidUrl;
  final String iosUrl;
  final bool isMaintenance;
  final String? message;

  AppVersionData({
    required this.minVersion,
    required this.latestVersion,
    required this.androidUrl,
    required this.iosUrl,
    this.isMaintenance = false,
    this.message,
  });

  factory AppVersionData.fromJson(Map<String, dynamic> json) {
    return AppVersionData(
      minVersion: json['minVersion'] ?? '0.0.0',
      latestVersion: json['latestVersion'] ?? '0.0.0',
      androidUrl: json['updateUrl']?['android'] ?? '',
      iosUrl: json['updateUrl']?['ios'] ?? '',
      isMaintenance: json['isMaintenance'] ?? false,
      message: json['message'],
    );
  }
}

class VersionService {
  final Dio _dio;
  AppVersionData? _cachedData;

  VersionService(this._dio);

  Future<AppVersionData?> getRemoteVersionData() async {
    try {
      final response = await _dio.get('/api/config/version');
      if (response.statusCode == 200) {
        _cachedData = AppVersionData.fromJson(response.data);
        return _cachedData;
      }
    } catch (e) {
      AppLogger.error("VersionService: Error fetching remote version", e);
    }
    return _cachedData;
  }

  Future<bool> isUpdateRequired() async {
    final remote = await getRemoteVersionData();
    if (remote == null) return false;

    final localVersion = await getLocalVersion();
    return _isVersionLower(localVersion, remote.minVersion);
  }

  Future<String> getLocalVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool _isVersionLower(String current, String target) {
    List<int> currentParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> targetParts = target
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (var i = 0; i < 3; i++) {
      int currentPart = currentParts.length > i ? currentParts[i] : 0;
      int targetPart = targetParts.length > i ? targetParts[i] : 0;

      if (currentPart < targetPart) return true;
      if (currentPart > targetPart) return false;
    }
    return false;
  }
}
