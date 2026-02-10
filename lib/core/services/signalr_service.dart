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

  // Callbacks - Voice Session oriented naming
  Function(String userId, String? voiceSessionId)? _onUserJoinedVoiceSession;
  Function(String userId, String? voiceSessionId)? _onUserLeftVoiceSession;
  Function(String userId, dynamic locationData)? _onRideLocationUpdate;
  // Previously: Function(String? rideId)? _onRideTerminated;

  // Broadcast Streams
  final _rideTerminatedController = StreamController<String?>.broadcast();
  final _rideCreatedController = StreamController<void>.broadcast();
  final _userJoinedController = StreamController<String>.broadcast();
  final _userLeftController = StreamController<String>.broadcast();
  final _hostChangedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _groupRideUpdatedController = StreamController<String>.broadcast();
  final _notificationReceivedController = StreamController<dynamic>.broadcast();

  Stream<String?> get rideTerminatedStream => _rideTerminatedController.stream;
  Stream<void> get rideCreatedStream => _rideCreatedController.stream;
  Stream<String> get userJoinedStream => _userJoinedController.stream;
  Stream<String> get userLeftStream => _userLeftController.stream;
  Stream<Map<String, dynamic>> get hostChangedStream =>
      _hostChangedController.stream;
  Stream<String> get groupRideUpdatedStream =>
      _groupRideUpdatedController.stream;
  Stream<dynamic> get notificationReceivedStream =>
      _notificationReceivedController.stream;

  final _voiceSessionRefreshController = StreamController<int>.broadcast();
  Stream<int> get voiceSessionRefreshStream =>
      _voiceSessionRefreshController.stream;

  // Active Voice Session Context
  String? _activeVoiceSessionId;

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

    _hubConnection!.on("UserJoinedVoiceSession", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final userId = arguments[0] as String;
        final voiceSessionId = arguments.length > 1
            ? arguments[1] as String?
            : null;
        AppLogger.info(
          "SignalR: User Joined Voice Session -> $userId (Session: ${voiceSessionId ?? _activeVoiceSessionId})",
        );
        _onUserJoinedVoiceSession?.call(
          userId,
          voiceSessionId ?? _activeVoiceSessionId,
        );
        _userJoinedController.add(userId);
      }
    });

    _hubConnection!.on("UserLeftVoiceSession", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final userId = arguments[0] as String;
        final voiceSessionId = arguments.length > 1
            ? arguments[1] as String?
            : null;
        AppLogger.info(
          "SignalR: User Left Voice Session -> $userId (Session: ${voiceSessionId ?? _activeVoiceSessionId})",
        );
        _onUserLeftVoiceSession?.call(
          userId,
          voiceSessionId ?? _activeVoiceSessionId,
        );
        _userLeftController.add(userId);
      }
    });

    _hubConnection!.on("RideCreated", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        // Assuming arguments[0] is rideId or ride object.
        // For list refresh, we might just need the signal.
        AppLogger.info("SignalR: Ride Created Event Received");
        _rideCreatedController.add(null);
      }
    });

    _hubConnection!.on("ReceiveRideLocationUpdate", (arguments) {
      if (arguments != null && arguments.length >= 2) {
        final userId = arguments[0] as String;
        final data = arguments[1];
        _onRideLocationUpdate?.call(userId, data);
      }
    });

    _hubConnection!.on("RideTerminated", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rideId = arguments[0] as String?;
        AppLogger.info("SignalR: Ride Terminated -> $rideId");
        // Broadcast event instead of single callback
        _rideTerminatedController.add(rideId);
        // Broadcast event instead of single callback
        _rideTerminatedController.add(rideId);
      }
    });

    _hubConnection!.on("HostChanged", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        AppLogger.info("SignalR: Host Changed -> $data");
        _hostChangedController.add(data);
      }
    });

    _hubConnection!.on("VoiceSessionRefresh", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final sessionId = arguments[0] as int;
        AppLogger.info("SignalR: VoiceSession Refresh -> $sessionId");
        _voiceSessionRefreshController.add(sessionId);
      }
    });

    _hubConnection!.on("GroupRideUpdated", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rideId = arguments[0].toString();
        AppLogger.info("SignalR: GroupRide Updated -> $rideId");
        _groupRideUpdatedController.add(rideId);
      }
    });

    _hubConnection!.on("ReceiveNotification", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final notification = arguments[0];
        AppLogger.info("SignalR: Received Notification -> $notification");
        _notificationReceivedController.add(notification);
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
      // Close local streams if needed, or keep open if service is singleton
      // _rideTerminatedController.close(); // Careful with singletons
      AppLogger.info("SignalR Connection Stopped");
    }
  }

  // --- Actions ---

  Future<void> joinVoiceSessionGroup(String voiceSessionId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke(
        "JoinVoiceSessionGroup",
        args: [voiceSessionId],
      );
      _activeVoiceSessionId = voiceSessionId;
      AppLogger.info("Joined Voice Session Group: $voiceSessionId");
    } catch (e) {
      AppLogger.error("Error joining voice session group", e);
    }
  }

  Future<void> leaveVoiceSessionGroup(String voiceSessionId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke(
        "LeaveVoiceSessionGroup",
        args: [voiceSessionId],
      );
      if (_activeVoiceSessionId == voiceSessionId) {
        _activeVoiceSessionId = null;
      }
      AppLogger.info("Left Voice Session Group: $voiceSessionId");
    } catch (e) {
      AppLogger.error("Error leaving voice session group", e);
    }
  }

  // --- Listeners Setters ---

  void setOnUserJoinedVoiceSession(
    Function(String userId, String? voiceSessionId) callback,
  ) {
    _onUserJoinedVoiceSession = callback;
  }

  void setOnUserLeftVoiceSession(
    Function(String userId, String? voiceSessionId) callback,
  ) {
    _onUserLeftVoiceSession = callback;
  }

  // DEPRECATED: Use rideTerminatedStream instead
  // void setOnRideTerminated(Function(String? rideId)? callback) {
  //   _onRideTerminated = callback;
  // }
}
