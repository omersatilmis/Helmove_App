import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../network/network_module.dart';
import '../utils/app_logger.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

class MessageSignalRService {
  HubConnection? _hubConnection;
  String? _resolvedBaseUrl;
  final AuthLocalDataSource authLocalDataSource;

  MessageSignalRService(this.authLocalDataSource);

  // Callbacks
  Function(dynamic message)? _onReceiveDirectMessage;
  Function(String senderId, bool isTyping)? _onUserTyping;

  // Streams (Broadcast - Çoklu dinleyici için)
  final _directMessageController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onDirectMessageReceived => _directMessageController.stream;

  final _messagesReadController = StreamController<void>.broadcast();
  Stream<void> get onMessagesRead => _messagesReadController.stream;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> init() async {
    if (_hubConnection != null) return;

    final token = await authLocalDataSource.getToken();
    if (token == null || token.trim().isEmpty) {
      AppLogger.warning("Message SignalR Init Failed: No Token");
      return;
    }

    try {
      _resolvedBaseUrl ??= await NetworkModule.getBaseUrl();
      final hubUrl = "${_resolvedBaseUrl!}messagehub";

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  await authLocalDataSource.getToken() ?? '',
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
        _directMessageController.add(message);
      }
    });

    _hubConnection!.on("MessagesRead", (arguments) {
      AppLogger.info("SignalR: MessagesRead event received");
      _messagesReadController.add(null);
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

  Future<void> sendTypingIndicator(int targetUserId, bool isTyping) async {
    if (_hubConnection == null ||
        _hubConnection!.state != HubConnectionState.Connected) {
      return;
    }

    try {
      await _hubConnection!.invoke(
        "SendTypingIndicator",
        args: [targetUserId.toString(), isTyping],
      );
    } catch (e) {
      AppLogger.error("Error sending typing indicator", e);
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
