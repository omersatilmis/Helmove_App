import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../utils/app_logger.dart';

class SignalRService {
  HubConnection? _hubConnection;
  final String _hubUrl = "${EnvConfig.localDeviceBaseUrl}callhub";
  final SharedPreferences sharedPreferences;

  SignalRService(this.sharedPreferences);

  // Callbacks
  // Callbacks -> Updated to include rideId
  Function(String userId, String? rideId)? _onUserJoinedRide;
  Function(String userId, String? rideId)? _onUserLeftRide;
  Function(String userId, dynamic locationData)? _onRideLocationUpdate;

  // Active Ride Context
  String? _activeRideId;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> init() async {
    if (_hubConnection != null) return;

    final token = sharedPreferences.getString('AUTH_TOKEN');
    if (token == null) {
      AppLogger.warning("SignalR Init Failed: No Token");
      return;
    }

    try {
      _hubConnection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _registerEventHandlers();

      await start();
    } catch (e) {
      AppLogger.error("SignalR Init Error", e);
    }
  }

  void _registerEventHandlers() {
    if (_hubConnection == null) return;

    _hubConnection!.on("UserJoinedRide", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final userId = arguments[0] as String;
        AppLogger.info(
          "SignalR: User Joined Ride -> $userId (Ride: $_activeRideId)",
        );
        _onUserJoinedRide?.call(userId, _activeRideId);
      }
    });

    _hubConnection!.on("UserLeftRide", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final userId = arguments[0] as String;
        AppLogger.info(
          "SignalR: User Left Ride -> $userId (Ride: $_activeRideId)",
        );
        _onUserLeftRide?.call(userId, _activeRideId);
      }
    });

    _hubConnection!.on("ReceiveRideLocationUpdate", (arguments) {
      if (arguments != null && arguments.length >= 2) {
        final userId = arguments[0] as String;
        final data = arguments[1];
        _onRideLocationUpdate?.call(userId, data);
      }
    });
  }

  Future<void> start() async {
    if (_hubConnection == null) return;

    if (_hubConnection!.state == HubConnectionState.Disconnected) {
      try {
        await _hubConnection!.start();
        AppLogger.info("SignalR Connection Started");
      } catch (e) {
        AppLogger.error("SignalR Connection Start Error", e);
      }
    }
  }

  Future<void> stop() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
      AppLogger.info("SignalR Connection Stopped");
    }
  }

  // --- Actions ---

  Future<void> joinRideGroup(String rideGroupId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("JoinRideGroup", args: [rideGroupId]);
      _activeRideId = rideGroupId;
      AppLogger.info("Joined Ride Group: $rideGroupId");
    } catch (e) {
      AppLogger.error("Error joining ride group", e);
    }
  }

  Future<void> leaveRideGroup(String rideGroupId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("LeaveRideGroup", args: [rideGroupId]);
      if (_activeRideId == rideGroupId) {
        _activeRideId = null;
      }
      AppLogger.info("Left Ride Group: $rideGroupId");
    } catch (e) {
      AppLogger.error("Error leaving ride group", e);
    }
  }

  // --- Listeners Setters ---

  void setOnUserJoinedRide(Function(String userId, String? rideId) callback) {
    _onUserJoinedRide = callback;
  }

  void setOnUserLeftRide(Function(String userId, String? rideId) callback) {
    _onUserLeftRide = callback;
  }
}
