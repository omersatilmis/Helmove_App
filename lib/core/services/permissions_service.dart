import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';

class PermissionsService {
  bool _startupRequestDone = false;
  bool _settingsOpenedForCallPermission = false;

  bool get _isWeb => kIsWeb;
  bool get _isIOS => !_isWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid =>
      !_isWeb && defaultTargetPlatform == TargetPlatform.android;

  List<Permission> _bluetoothPermissions() {
    if (_isIOS) {
      return <Permission>[Permission.bluetooth];
    }
    return <Permission>[Permission.bluetoothConnect, Permission.bluetoothScan];
  }

  Future<bool> ensureCallPermissions({
    bool requestIfNeeded = false,
    bool openSettingsOnFailure = false,
  }) async {
    if (_isWeb) return true;

    // Call flow is blocked only by essential permissions.
    // iOS: microphone
    // Android: microphone + phone
    final permissions = <Permission>[
      Permission.microphone,
      if (_isAndroid) Permission.phone,
    ];

    Map<Permission, PermissionStatus> results = await _checkPermissions(
      permissions,
    );
    final micOk = _isGranted(results[Permission.microphone]);
    final phoneOk = _isAndroid ? _isGranted(results[Permission.phone]) : true;

    AppLogger.info(
      'PermissionsService: call status before request '
      'mic=${results[Permission.microphone]} '
      'phone=${_isAndroid ? results[Permission.phone] : 'n/a'} '
      'platform=${defaultTargetPlatform.name}',
    );

    final essentialOk = micOk && phoneOk;

    if (!essentialOk) {
      if (requestIfNeeded) {
        AppLogger.warning(
          'PermissionsService: call permissions missing. Requesting now...',
        );
        results = await _requestPermissions(permissions);

        final micOkAfterRequest = _isGranted(results[Permission.microphone]);
        final phoneOkAfterRequest = _isAndroid
            ? _isGranted(results[Permission.phone])
            : true;

        AppLogger.info(
          'PermissionsService: call status after request '
          'mic=${results[Permission.microphone]} '
          'phone=${_isAndroid ? results[Permission.phone] : 'n/a'} '
          'platform=${defaultTargetPlatform.name}',
        );

        final essentialOkAfterRequest = micOkAfterRequest && phoneOkAfterRequest;
        if (essentialOkAfterRequest) {
          return true;
        }

        AppLogger.warning(
          'PermissionsService: call permissions denied (AFTER REQUEST) '
          'mic=$micOkAfterRequest phone=$phoneOkAfterRequest platform=${defaultTargetPlatform.name}',
        );
        if (openSettingsOnFailure && _shouldOpenSettingsForCall(results)) {
          await openSettings();
        }
        return false;
      }

      AppLogger.warning(
        'PermissionsService: call permissions denied (CHECK ONLY) '
        'mic=$micOk phone=$phoneOk platform=${defaultTargetPlatform.name}',
      );
      if (openSettingsOnFailure && _shouldOpenSettingsForCall(results)) {
        await openSettings();
      }
      return false;
    }

    return true;
  }

  Future<bool> ensureVoiceSessionPermissions({
    bool requestLocation = true,
  }) async {
    if (_isWeb) return true;

    final permissions = <Permission>[
      Permission.microphone,
      ..._bluetoothPermissions(),
      Permission.notification,
    ];

    final results = await _checkPermissions(permissions);
    final micOk = _isGranted(results[Permission.microphone]);
    final btOk = _isIOS
        ? _isGranted(results[Permission.bluetooth])
        : _isGranted(results[Permission.bluetoothConnect]);
    final notificationOk = _isGranted(results[Permission.notification]);

    if (!micOk || !btOk || !notificationOk) {
      AppLogger.warning(
        'PermissionsService: voice permissions denied (CHECK ONLY) '
        'mic=$micOk bt=$btOk notification=$notificationOk platform=${defaultTargetPlatform.name}',
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

  /// Called at app startup (Home Page) to request all necessary permissions at once.
  /// Returns [true] if essential permissions are granted.
  Future<bool> requestAllStartupPermissions() async {
    if (_isWeb) return true;

    if (_startupRequestDone) {
      AppLogger.info(
        'PermissionsService: Startup permissions already requested. Skipping.',
      );
      return true;
    }
    _startupRequestDone = true;

    final foregroundPermissions = <Permission>[
      Permission.microphone,
      ..._bluetoothPermissions(),
      Permission.notification,
      if (_isAndroid) Permission.phone,
      Permission.locationWhenInUse,
    ];

    AppLogger.info('PermissionsService: Requesting FOREGROUND permissions...');
    final foregroundResults = await _requestPermissions(foregroundPermissions);
    final results = <Permission, PermissionStatus>{...foregroundResults};

    final whenInUseGranted = _isGranted(
      foregroundResults[Permission.locationWhenInUse],
    );

    if (whenInUseGranted) {
      AppLogger.info(
        'PermissionsService: "When In Use" granted. Requesting BACKGROUND location...',
      );
      final bgResults = await _requestPermissions([Permission.locationAlways]);
      results.addAll(bgResults);
    } else {
      AppLogger.warning(
        'PermissionsService: "When In Use" denied. Skipping Background Location request.',
      );
    }

    final micOk = _isGranted(results[Permission.microphone]);
    final btOk = _isIOS
        ? _isGranted(results[Permission.bluetooth])
        : _isGranted(results[Permission.bluetoothConnect]);
    final notificationOk = _isGranted(results[Permission.notification]);
    final phoneOk = _isAndroid ? _isGranted(results[Permission.phone]) : true;
    final locationWhenInUseOk = _isGranted(
      results[Permission.locationWhenInUse],
    );
    final locationAlwaysOk = _isGranted(results[Permission.locationAlways]);
    final locationOk = locationWhenInUseOk || locationAlwaysOk;

    final allOk = micOk && btOk && notificationOk && locationOk && phoneOk;

    if (!allOk) {
      AppLogger.warning(
        'PermissionsService: Startup permissions incomplete. '
        'mic=$micOk bt=$btOk notification=$notificationOk location=$locationOk phone=$phoneOk platform=${defaultTargetPlatform.name}',
      );
    } else {
      AppLogger.info('PermissionsService: All startup permissions granted.');
    }

    return allOk;
  }

  Future<Map<Permission, PermissionStatus>> _requestPermissions(
    List<Permission> permissions,
  ) async {
    if (permissions.isEmpty) return <Permission, PermissionStatus>{};
    return permissions.request();
  }

  Future<Map<Permission, PermissionStatus>> _checkPermissions(
    List<Permission> permissions,
  ) async {
    final results = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = await permission.status;
    }
    return results;
  }

  bool _isGranted(PermissionStatus? status) {
    if (status == null) return false;
    return status.isGranted || status.isLimited;
  }

  bool _shouldOpenSettingsForCall(Map<Permission, PermissionStatus> results) {
    final mic = results[Permission.microphone];
    final phone = _isAndroid ? results[Permission.phone] : null;

    final settingsRequired = (mic?.isPermanentlyDenied ?? false) ||
        (mic?.isRestricted ?? false) ||
        (_isAndroid &&
            ((phone?.isPermanentlyDenied ?? false) ||
                (phone?.isRestricted ?? false)));

    if (!settingsRequired) {
      return false;
    }

    if (_settingsOpenedForCallPermission) {
      return false;
    }
    _settingsOpenedForCallPermission = true;
    return true;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
