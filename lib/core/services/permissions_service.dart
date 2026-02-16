import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';

class PermissionsService {
  Future<bool> ensureCallPermissions() async {
    final permissions = <Permission>[
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
      Permission.phone,
    ];

    final results = await _requestPermissions(permissions);
    final micOk = _isGranted(results[Permission.microphone]);
    final btConnectOk = _isGranted(results[Permission.bluetoothConnect]);
    final btScanOk = _isGranted(results[Permission.bluetoothScan]);
    final phoneOk = _isGranted(results[Permission.phone]);
    final notificationOk = _isGranted(results[Permission.notification]);

    if (!micOk || !btConnectOk || !btScanOk || !phoneOk || !notificationOk) {
      AppLogger.warning(
        'PermissionsService: call permissions denied '
        'mic=$micOk btConnect=$btConnectOk btScan=$btScanOk phone=$phoneOk notification=$notificationOk',
      );
      return false;
    }

    return true;
  }

  Future<bool> ensureVoiceSessionPermissions({
    bool requestLocation = true,
  }) async {
    final permissions = <Permission>[
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
    ];

    if (requestLocation) {
      await Permission.locationWhenInUse.request();
      await Permission.locationAlways.request();
    }

    final results = await _requestPermissions(permissions);
    final micOk = _isGranted(results[Permission.microphone]);
    final btConnectOk = _isGranted(results[Permission.bluetoothConnect]);
    final btScanOk = _isGranted(results[Permission.bluetoothScan]);
    final notificationOk = _isGranted(results[Permission.notification]);

    if (!micOk || !btConnectOk || !btScanOk || !notificationOk) {
      AppLogger.warning(
        'PermissionsService: voice permissions denied '
        'mic=$micOk btConnect=$btConnectOk btScan=$btScanOk notification=$notificationOk',
      );
      return false;
    }

    if (requestLocation) {
      final locationOk =
          _isGranted(await Permission.locationWhenInUse.status) ||
          _isGranted(await Permission.locationAlways.status);
      if (!locationOk) {
        AppLogger.warning('PermissionsService: location permissions denied');
        return false;
      }
    }

    return true;
  }

  bool _startupRequestDone = false;

  /// Called at app startup (Home Page) to request all necessary permissions at once.
  /// Returns [true] if essential permissions (Mic, Bluetooth, Notification) are granted.
  Future<bool> requestAllStartupPermissions() async {
    if (_startupRequestDone) {
      AppLogger.info(
        'PermissionsService: Startup permissions already requested. Skipping.',
      );
      return true;
    }
    _startupRequestDone = true;

    // We request Location only if needed, but for startup we focus on communication.
    // Spec: Mic, Bluetooth, Notification.
    final permissions = <Permission>[
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
    ];

    AppLogger.info('PermissionsService: Requesting startup permissions...');
    final results = await _requestPermissions(permissions);

    final micOk = _isGranted(results[Permission.microphone]);
    final btConnectOk = _isGranted(results[Permission.bluetoothConnect]);
    // BluetoothScan is often optional for simple HFP but good to have.
    final notificationOk = _isGranted(results[Permission.notification]);

    final allOk = micOk && btConnectOk && notificationOk;

    if (!allOk) {
      AppLogger.warning(
        'PermissionsService: Startup permissions incomplete. '
        'mic=$micOk btConnect=$btConnectOk notification=$notificationOk',
      );
    } else {
      AppLogger.info('PermissionsService: All startup permissions granted.');
    }

    return allOk;
  }

  Future<Map<Permission, PermissionStatus>> _requestPermissions(
    List<Permission> permissions,
  ) async {
    final results = await permissions.request();
    return results;
  }

  bool _isGranted(PermissionStatus? status) {
    if (status == null) return false;
    return status.isGranted || status.isLimited;
  }
}
