import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // "generic" genellikle emülatörleri işaret eder
      if (androidInfo.fingerprint.contains("generic") ||
          androidInfo.model.contains("sdk") ||
          androidInfo.product.contains("sdk")) {
        return EnvConfig.emulatorBaseUrl;
      } else {
        return EnvConfig.localDeviceBaseUrl;
      }
    } else if (Platform.isIOS) {
      // iOS Simulator kontrolü
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      if (!iosInfo.isPhysicalDevice) {
        return EnvConfig.iosSimulatorBaseUrl;
      }
      return EnvConfig.localDeviceBaseUrl;
    }

    return EnvConfig.localDeviceBaseUrl;
  }

  static Future<Dio> provideDio(SharedPreferences sharedPreferences) async {
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

    // Auth Interceptor'ı ekle
    dio.interceptors.add(AuthInterceptor(sharedPreferences));

    // İstekleri loglamak için Interceptor ekleyebiliriz
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
