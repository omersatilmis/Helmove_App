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

    final results = await _checkPermissions(permissions);
    final micOk = _isGranted(results[Permission.microphone]);
    final btConnectOk = _isGranted(results[Permission.bluetoothConnect]);
    final btScanOk = _isGranted(results[Permission.bluetoothScan]);
    final phoneOk = _isGranted(results[Permission.phone]);
    final notificationOk = _isGranted(results[Permission.notification]);

    if (!micOk || !btConnectOk || !btScanOk || !phoneOk || !notificationOk) {
      AppLogger.warning(
        'PermissionsService: call permissions denied (CHECK ONLY) '
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

    // Note: requestLocation is ignored for checking,
    // we only check if the user asked for it in startup.
    // Or we should check it if 'requestLocation' is true but NOT request it.
    // The user said "Don't ask anywhere else". So we just check.

    final results = await _checkPermissions(permissions);
    final micOk = _isGranted(results[Permission.microphone]);
    final btConnectOk = _isGranted(results[Permission.bluetoothConnect]);
    final btScanOk = _isGranted(results[Permission.bluetoothScan]);
    final notificationOk = _isGranted(results[Permission.notification]);

    if (!micOk || !btConnectOk || !btScanOk || !notificationOk) {
      AppLogger.warning(
        'PermissionsService: voice permissions denied (CHECK ONLY) '
        'mic=$micOk btConnect=$btConnectOk btScan=$btScanOk notification=$notificationOk',
      );
      return false;
    }

    if (requestLocation) {
      final locationOk =
          _isGranted(await Permission.locationWhenInUse.status) ||
          _isGranted(await Permission.locationAlways.status);
      if (!locationOk) {
        AppLogger.warning(
          'PermissionsService: location permissions denied (CHECK ONLY)',
        );
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
    final foregroundPermissions = <Permission>[
      Permission.microphone,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.notification,
      Permission.phone, // [NEW] User request: All permissions
      Permission.locationWhenInUse, // [NEW] User request: Ask at startup
      // Permission.locationAlways, // [FIX] Android 11+ crash: Cannot request background location with others
    ];

    AppLogger.info('PermissionsService: Requesting FOREGROUND permissions...');
    final foregroundResults = await _requestPermissions(foregroundPermissions);

    // Merge results
    Map<Permission, PermissionStatus> results = {...foregroundResults};

    // Check if we can proceed to Background Location
    // Android 11+ requires 'When In Use' to be granted BEFORE asking 'Always'.
    final whenInUseGranted = _isGranted(
      foregroundResults[Permission.locationWhenInUse],
    );

    if (whenInUseGranted) {
      AppLogger.info(
        'PermissionsService: "When In Use" granted. Requesting BACKGROUND location...',
      );
      // Stage 2: Background Location
      // On Android 11+, this will likely take the user to System Settings
      // or show a dialog instructing them to select "Allow all the time".
      final bgResults = await _requestPermissions([Permission.locationAlways]);
      results.addAll(bgResults);
    } else {
      AppLogger.warning(
        'PermissionsService: "When In Use" denied. Skipping Background Location request.',
      );
    }

    final micOk = _isGranted(results[Permission.microphone]);
    final btConnectOk = _isGranted(results[Permission.bluetoothConnect]);
    // BluetoothScan is often optional for simple HFP but good to have.
    final notificationOk = _isGranted(results[Permission.notification]);
    final phoneOk = _isGranted(results[Permission.phone]); // [NEW] Check phone

    // [NEW] Check location
    final locationWhenInUseOk = _isGranted(
      results[Permission.locationWhenInUse],
    );
    final locationAlwaysOk = _isGranted(results[Permission.locationAlways]);
    final locationOk = locationWhenInUseOk || locationAlwaysOk;

    // [NEW] User request: Location is now considered part of startup requirements of FULL experience
    // Note: If user didn't grant 'Always', we might still return true if 'WhenInUse' satisfied basic needs?
    // User said: "Tam sesli sohbet deneyimi için ... gereklidir."
    // If 'Always' is denied, should we show red bar?
    // The user's flow says "Kullanıcı ilk aşamayı kabul ettikten sonra... ayrıca ister."
    // If they deny 'Always', maybe valid for basic usage?
    // BUT the 'allOk' logic below determines if we show the red bar.
    // If I enforce 'Always', many users will see red bar.
    // However, the user insists on asking it.
    // I will consider 'locationOk' as (WhenInUse OR Always) for now,
    // so if Always is denied but WhenInUse is granted, we DON'T show red bar?
    // Let's stick to strict compliance for now: allOk implies everything we asked for?
    // Actually, 'locationOk' line 125 uses OR. So if 'WhenInUse' is OK, 'locationOk' is OK.
    // So user won't be blocked by Red Bar if they deny 'Always' (unless we change logic).
    // Let's keep it lenient: If WhenInUse is OK, the app works.

    final allOk =
        micOk && btConnectOk && notificationOk && locationOk && phoneOk;

    if (!allOk) {
      AppLogger.warning(
        'PermissionsService: Startup permissions incomplete. '
        'mic=$micOk btConnect=$btConnectOk notification=$notificationOk location=$locationOk phone=$phoneOk',
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

  Future<Map<Permission, PermissionStatus>> _checkPermissions(
    List<Permission> permissions,
  ) async {
    final Map<Permission, PermissionStatus> results = {};
    for (var permission in permissions) {
      results[permission] = await permission.status;
    }
    return results;
  }

  bool _isGranted(PermissionStatus? status) {
    if (status == null) return false;
    return status.isGranted || status.isLimited;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
