import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helmove/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:helmove/core/config/env_config.dart';
import 'package:helmove/core/network/auth_interceptor.dart';
import 'package:helmove/core/network/auth_bootstrap_gate.dart';
import 'package:helmove/core/network/etag_interceptor.dart';

class NetworkModule {
  static String? _cachedBaseUrl;
  static Future<String>? _baseUrlFuture;

  static Future<String> getBaseUrl() async {
    final cached = _cachedBaseUrl;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    if (_baseUrlFuture != null) {
      return _baseUrlFuture!;
    }

    final completer = _resolveBaseUrl();
    _baseUrlFuture = completer;
    try {
      final resolved = await completer;
      _cachedBaseUrl = resolved;
      return resolved;
    } finally {
      _baseUrlFuture = null;
    }
  }

  static Future<String> _resolveBaseUrl() async {
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
        return EnvConfig.productionBaseUrl;
      }
    } else if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      if (!iosInfo.isPhysicalDevice) {
        return EnvConfig.iosSimulatorBaseUrl;
      }
      return EnvConfig.productionBaseUrl;
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return EnvConfig.productionBaseUrl;
    }

    return EnvConfig.productionBaseUrl;
  }

  static Future<Dio> provideDio(
    AuthLocalDataSource localDataSource, {
    required AuthBootstrapGate authBootstrapGate,
    Future<void> Function()? onAuthInvalidated,
    Future<void> Function(String token)? onTokenRefreshed,
  }) async {
    final baseUrl = await getBaseUrl();
    final sharedPreferences = await SharedPreferences.getInstance();

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
        authBootstrapGate,
        onAuthInvalidated,
        onTokenRefreshed,
      ),
    );

    // Order is important:
    // AuthInterceptor -> ETagInterceptor -> LogInterceptor
    dio.interceptors.add(ETagInterceptor(sharedPreferences));

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
