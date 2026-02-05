import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../utils/app_logger.dart';

class MessageSignalRService {
  HubConnection? _hubConnection;
  final String _hubUrl = "${EnvConfig.localDeviceBaseUrl}messagehub";
  final SharedPreferences sharedPreferences;

  MessageSignalRService(this.sharedPreferences);

  // Callbacks
  Function(dynamic message)? _onReceiveDirectMessage;
  Function(String senderId, bool isTyping)? _onUserTyping;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> init() async {
    if (_hubConnection != null) return;

    final token = sharedPreferences.getString('AUTH_TOKEN');
    if (token == null) {
      AppLogger.warning("Message SignalR Init Failed: No Token");
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
      AppLogger.error("Message SignalR Init Error", e);
    }
  }

  void _registerEventHandlers() {
    if (_hubConnection == null) return;

    _hubConnection!.on("ReceiveDirectMessage", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final message = arguments[0];
        AppLogger.info("SignalR: ReceiveDirectMessage");
        _onReceiveDirectMessage?.call(message);
      }
    });

    _hubConnection!.on("UserTyping", (arguments) {
      if (arguments != null && arguments.length >= 2) {
        final senderId = arguments[0] as String;
        final isTyping = arguments[1] as bool;
        _onUserTyping?.call(senderId, isTyping);
      }
    });
  }

  Future<void> start() async {
    if (_hubConnection == null) return;

    if (_hubConnection!.state == HubConnectionState.Disconnected) {
      try {
        await _hubConnection!.start();
        AppLogger.info("Message SignalR Connection Started");
      } catch (e) {
        AppLogger.error("Message SignalR Connection Start Error", e);
      }
    }
  }

  Future<void> stop() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
      AppLogger.info("Message SignalR Connection Stopped");
    }
  }

  // --- Listeners Setters ---

  void setOnReceiveDirectMessage(Function(dynamic message) callback) {
    _onReceiveDirectMessage = callback;
  }

  void setOnUserTyping(Function(String senderId, bool isTyping) callback) {
    _onUserTyping = callback;
  }
}
