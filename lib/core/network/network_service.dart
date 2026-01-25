import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:moto_comm_app_1/core/utils/app_logger.dart';

/// NetworkService - İnternet bağlantısını yönetir
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Bağlantı değişikliklerini dinler
  Stream<bool> get connectionStream => _connectivity.onConnectivityChanged.map(
    (results) => _checkResults(results),
  );

  /// Başlangıçta çağrılmalı (main.dart veya DI'da)
  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = _checkResults(results);
    AppLogger.info("NetworkService initialized. Connected: $_isConnected");

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isConnected = _checkResults(results);
      AppLogger.info("Connection changed: $_isConnected");
    });
  }

  /// Bağlantı durumunu kontrol eder
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = _checkResults(results);
    return _isConnected;
  }

  bool _checkResults(List<ConnectivityResult> results) {
    // Eğer hiç bağlantı yoksa veya sadece "none" varsa bağlantı yok demektir
    if (results.isEmpty) return false;
    return !results.every((r) => r == ConnectivityResult.none);
  }

  /// Servisi kapat
  void dispose() {
    _subscription?.cancel();
  }
}
