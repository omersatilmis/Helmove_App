import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../network/network_module.dart';
import '../utils/app_logger.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/presence/data/models/user_presence_model.dart';

class MessageSignalRService {
  HubConnection? _hubConnection;
  String? _resolvedBaseUrl;
  final AuthLocalDataSource authLocalDataSource;

  // Auto-reconnect retry'leri tükendikten sonra manuel reconnect için.
  bool _intentionalStop = false;
  Timer? _manualReconnectTimer;

  MessageSignalRService(this.authLocalDataSource);

  // Callbacks
  Function(dynamic message)? _onReceiveDirectMessage;
  Function(String senderId, bool isTyping)? _onUserTyping;

  // Streams (Broadcast - Çoklu dinleyici için)
  final _directMessageController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onDirectMessageReceived =>
      _directMessageController.stream;

  final _messagesReadController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get onMessagesRead => _messagesReadController.stream;

  final _messagesReadPayloadController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onMessagesReadPayload =>
      _messagesReadPayloadController.stream;

  final _messageEditedController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onMessageEdited => _messageEditedController.stream;

  final _messageDeletedController = StreamController<int>.broadcast();
  Stream<int> get onMessageDeleted => _messageDeletedController.stream;

  final _userTypingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onUserTypingStream =>
      _userTypingStreamController.stream;

  // ── Presence Streams ──────────────────────────────────────────────────────

  /// İlk bağlantıda gelen çevrimiçi arkadaş ID listesi.
  final _onlineFriendsController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get onOnlineFriends => _onlineFriendsController.stream;

  /// Herhangi bir kullanıcının online/offline durumu değiştiğinde tetiklenir.
  final _userStatusChangedController =
      StreamController<UserPresenceModel>.broadcast();
  Stream<UserPresenceModel> get onUserStatusChanged =>
      _userStatusChangedController.stream;

  /// Heartbeat'e karşılık sunucudan gelen ACK.
  final _heartbeatResponseController = StreamController<void>.broadcast();
  Stream<void> get onHeartbeatResponse => _heartbeatResponseController.stream;

  /// Bağlantı durumu — BehaviorSubject: yeni dinleyici her zaman son değeri alır.
  final _connectionStateController = BehaviorSubject<HubConnectionState>.seeded(
    HubConnectionState.Disconnected,
  );
  Stream<HubConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

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
          .withAutomaticReconnect(
            // Exponential backoff: 2s, 4s, 8s, 16s, 32s, 60s (sonrasında 60s sabit)
            retryDelays: [2000, 4000, 8000, 16000, 32000, 60000],
          )
          .build();

      _hubConnection!.onreconnecting(({error}) {
        AppLogger.warning("Message SignalR: Reconnecting... $error");
        _connectionStateController.add(HubConnectionState.Reconnecting);
      });

      _hubConnection!.onreconnected(({connectionId}) {
        AppLogger.info("Message SignalR: Reconnected. id=$connectionId");
        _manualReconnectTimer?.cancel();
        _connectionStateController.add(HubConnectionState.Connected);
      });

      _hubConnection!.onclose(({error}) {
        AppLogger.warning("Message SignalR: Connection closed. $error");
        _connectionStateController.add(HubConnectionState.Disconnected);
        _scheduleManualReconnect();
      });

      _registerEventHandlers();

      _intentionalStop = false;
      _manualReconnectTimer?.cancel();
      await start();
    } catch (e) {
      AppLogger.error("Message SignalR Init Error", e);
    }
  }

  /// onclose sonrası bağlanana kadar belirli aralıklarla yeniden dener.
  void _scheduleManualReconnect() {
    if (_intentionalStop || _hubConnection == null) return;
    _manualReconnectTimer?.cancel();
    _manualReconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (_intentionalStop || _hubConnection == null) return;
      if (_hubConnection!.state == HubConnectionState.Connected) return;
      await start();
      if (_hubConnection?.state != HubConnectionState.Connected) {
        _scheduleManualReconnect();
      } else {
        AppLogger.info("Message SignalR: Manual reconnect succeeded");
      }
    });
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
      if (arguments != null && arguments.length >= 2) {
        // Backend sends: MessagesRead(readerId, messageIds)
        final rawIds = arguments[1];
        List<int> messageIds = [];
        if (rawIds is List) {
          messageIds = rawIds
              .map((e) => (e is int) ? e : int.tryParse(e.toString()) ?? 0)
              .where((id) => id > 0)
              .toList();
        }
        _messagesReadPayloadController.add(arguments[0]);
        _messagesReadController.add(messageIds);
      }
    });

    _hubConnection!.on("UserTyping", (arguments) {
      if (arguments != null && arguments.length >= 2) {
        final senderId = arguments[0] as String;
        final isTyping = arguments[1] as bool;
        _onUserTyping?.call(senderId, isTyping);
        _userTypingStreamController.add({'senderId': senderId, 'isTyping': isTyping});
      }
    });

    _hubConnection!.on("MessageEdited", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final editedMessage = arguments[0];
        AppLogger.info("SignalR: MessageEdited");
        _messageEditedController.add(editedMessage);
      }
    });

    _hubConnection!.on("MessageDeleted", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final messageId = arguments[0] as int;
        AppLogger.info("SignalR: MessageDeleted");
        _messageDeletedController.add(messageId);
      }
    });

    // ── Presence Event Handlers ──────────────────────────────────────────────

    _hubConnection!.on("OnlineFriends", (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments[0];
      final ids = <int>[];
      if (raw is List) {
        for (final item in raw) {
          final id = item is int ? item : int.tryParse(item.toString());
          if (id != null) ids.add(id);
        }
      }
      AppLogger.info("SignalR: OnlineFriends count=${ids.length}");
      _onlineFriendsController.add(ids);
    });

    _hubConnection!.on("UserStatusChanged", (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      try {
        final raw = arguments[0];
        final map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        final model = UserPresenceModel.fromMap(map);
        AppLogger.info(
          "SignalR: UserStatusChanged userId=${model.userId} online=${model.isOnline}",
        );
        _userStatusChangedController.add(model);
      } catch (e) {
        AppLogger.error("SignalR: UserStatusChanged parse error", e);
      }
    });

    _hubConnection!.on("HeartbeatResponse", (arguments) {
      AppLogger.info("SignalR: HeartbeatResponse received");
      _heartbeatResponseController.add(null);
    });
  }

  Future<void> start() async {
    if (_hubConnection == null) return;

    if (_hubConnection!.state == HubConnectionState.Disconnected) {
      try {
        _connectionStateController.add(HubConnectionState.Connecting);
        await _hubConnection!.start();
        _connectionStateController.add(HubConnectionState.Connected);
        AppLogger.info("Message SignalR Connection Started");
      } catch (e) {
        _connectionStateController.add(HubConnectionState.Disconnected);
        AppLogger.error("Message SignalR Connection Start Error", e);
      }
    }
  }

  Future<void> stop() async {
    _intentionalStop = true;
    _manualReconnectTimer?.cancel();
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
      _connectionStateController.add(HubConnectionState.Disconnected);
      AppLogger.info("Message SignalR Connection Stopped");
    }
  }

  /// Sunucuya heartbeat gönderir. Sadece bağlıyken çağrılmalı.
  Future<void> sendHeartbeat() async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("Heartbeat");
    } catch (e) {
      AppLogger.error("Message SignalR: Heartbeat invoke error", e);
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

  void dispose() {
    _intentionalStop = true;
    _manualReconnectTimer?.cancel();
    _directMessageController.close();
    _messagesReadController.close();
    _messagesReadPayloadController.close();
    _messageEditedController.close();
    _messageDeletedController.close();
    _userTypingStreamController.close();
    _onlineFriendsController.close();
    _userStatusChangedController.close();
    _heartbeatResponseController.close();
    _connectionStateController.close();
  }
}
