import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../config/env_config.dart';

final GetIt backgroundSl = GetIt.asNewInstance();

bool _backgroundDiInitialized = false;

/// Registers only background-safe dependencies.
/// UI-bound plugins and full app DI are intentionally excluded.
Future<void> initBackgroundDi() async {
  if (_backgroundDiInitialized) {
    return;
  }

  backgroundSl.allowReassignment = true;

  if (!backgroundSl.isRegistered<Dio>()) {
    backgroundSl.registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: EnvConfig.localDeviceBaseUrl,
          connectTimeout: EnvConfig.connectTimeout,
          receiveTimeout: EnvConfig.receiveTimeout,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
  }

  _backgroundDiInitialized = true;
}
