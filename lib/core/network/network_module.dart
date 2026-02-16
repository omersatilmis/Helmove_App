import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../config/env_config.dart';
import 'auth_interceptor.dart';

class NetworkModule {
  static Future<String> getBaseUrl() async {
    if (kIsWeb) {
      return EnvConfig.webBaseUrl;
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // "generic" genellikle emulatorleri isaret eder
      if (androidInfo.fingerprint.contains('generic') ||
          androidInfo.model.contains('sdk') ||
          androidInfo.product.contains('sdk')) {
        return EnvConfig.emulatorBaseUrl;
      } else {
        return EnvConfig.localDeviceBaseUrl;
      }
    } else if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      if (!iosInfo.isPhysicalDevice) {
        return EnvConfig.iosSimulatorBaseUrl;
      }
      return EnvConfig.localDeviceBaseUrl;
    }

    return EnvConfig.localDeviceBaseUrl;
  }

  static Future<Dio> provideDio(
    AuthLocalDataSource localDataSource, {
    Future<void> Function()? onAuthInvalidated,
    Future<void> Function(String token)? onTokenRefreshed,
  }) async {
    final baseUrl = await getBaseUrl();

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // A separate dio without the auth interceptor (used for refresh flow).
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        dio,
        refreshDio,
        localDataSource,
        onAuthInvalidated,
        onTokenRefreshed,
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    return dio;
  }
}
