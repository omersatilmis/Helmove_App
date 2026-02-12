import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network_module.dart';
import '../utils/app_logger.dart';

class SignalRService {
  HubConnection? _hubConnection;
  String? _resolvedBaseUrl;
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

  // ============================================================
  // P2P CALL SIGNALING STREAMS
  // ============================================================
  final _incomingCallController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callAcceptedController = StreamController<String>.broadcast();
  final _callRejectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callEndedController = StreamController<String>.broadcast();
  final _offerController = StreamController<Map<String, dynamic>>.broadcast();
  final _answerController = StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _callRequestFailedController = StreamController<String>.broadcast();
  final _callActionFailedController = StreamController<String>.broadcast();
  final _signalDeliveryFailedController = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get incomingCallStream =>
      _incomingCallController.stream;
  Stream<String> get callAcceptedStream => _callAcceptedController.stream;
  Stream<Map<String, dynamic>> get callRejectedStream =>
      _callRejectedController.stream;
  Stream<String> get callEndedStream => _callEndedController.stream;
  Stream<Map<String, dynamic>> get offerStream => _offerController.stream;
  Stream<Map<String, dynamic>> get answerStream => _answerController.stream;
  Stream<Map<String, dynamic>> get iceCandidateStream =>
      _iceCandidateController.stream;
  Stream<String> get callRequestFailedStream =>
      _callRequestFailedController.stream;
  Stream<String> get callActionFailedStream =>
      _callActionFailedController.stream;
  Stream<String> get signalDeliveryFailedStream =>
      _signalDeliveryFailedController.stream;

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
    final token = sharedPreferences.getString('AUTH_TOKEN');
    if (token == null || token.trim().isEmpty) {
      AppLogger.warning("SignalR Init Failed: No Token");
      return;
    }

    try {
      _resolvedBaseUrl ??= await NetworkModule.getBaseUrl();
      final hubUrl = "${_resolvedBaseUrl!}callhub";

      if (_hubConnection != null) {
        if (_hubConnection!.state == HubConnectionState.Disconnected) {
          await start();
        }
        return;
      }

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async =>
                  sharedPreferences.getString('AUTH_TOKEN') ?? '',
            ),
          )
          .withAutomaticReconnect()
          .build();

      AppLogger.info("SignalR: Registering event handlers...");
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
        final userId = _asString(arguments[0]);
        if (userId == null || userId.isEmpty) return;
        final data = arguments[1];
        _onRideLocationUpdate?.call(userId, data);
      }
    });

    _hubConnection!.on("RideTerminated", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final rideId = _asString(arguments[0]);
        AppLogger.info("SignalR: Ride Terminated -> $rideId");
        _rideTerminatedController.add(rideId);
      }
    });

    _hubConnection!.on("HostChanged", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        if (arguments[0] is! Map) return;
        final data = Map<String, dynamic>.from(arguments[0] as Map);
        AppLogger.info("SignalR: Host Changed -> $data");
        _hostChangedController.add(data);
      }
    });

    _hubConnection!.on("VoiceSessionRefresh", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final sessionId = _asInt(arguments[0]);
        if (sessionId == null) return;
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

    // ============================================================
    // P2P CALL SIGNALING HANDLERS
    // ============================================================

    _hubConnection!.on("ReceiveCallRequest", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        AppLogger.info("SignalR: ReceiveCallRequest RAW ARGS: $arguments");

        String? callerId;
        String? callerDisplayName;
        int? callId;

        // Backend can send arguments as a single object or positional args
        if (arguments[0] is Map) {
          final data = Map<String, dynamic>.from(arguments[0] as Map);
          callerId =
              _readString(data, const [
                'callerId',
                'CallerId',
                'fromUserId',
                'FromUserId',
                'callerUserId',
                'CallerUserId',
              ]) ??
              '';
          callerDisplayName = _readString(data, const [
            'callerDisplayName',
            'CallerDisplayName',
            'displayName',
            'DisplayName',
            'callerName',
            'CallerName',
          ]);
          callId = _readInt(data, const ['callId', 'CallId', 'id', 'Id']);
        } else {
          callerId = arguments[0]?.toString();
          callerDisplayName = arguments.length > 1
              ? arguments[1]?.toString()
              : null;
          callId = arguments.length > 2
              ? int.tryParse(arguments[2]?.toString() ?? '')
              : null;
        }

        if (callerId == null || callerId.isEmpty) {
          AppLogger.warning("SignalR: ReceiveCallRequest: callerId is NULL!");
          return;
        }

        AppLogger.info(
          "SignalR: Gelen arama <- $callerId (Name: $callerDisplayName, CallId: $callId)",
        );
        _incomingCallController.add({
          'callerId': callerId,
          'callerDisplayName': callerDisplayName,
          'callId': callId,
        });
      } else {
        AppLogger.warning(
          "SignalR: ReceiveCallRequest received but arguments are null or empty!",
        );
      }
    });

    _hubConnection!.on("CallAccepted", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final targetUserId = _asString(arguments[0]);
        if (targetUserId == null || targetUserId.isEmpty) return;
        AppLogger.info("SignalR: Arama kabul edildi <- $targetUserId");
        _callAcceptedController.add(targetUserId);
      }
    });

    _hubConnection!.on("CallRejected", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final targetUserId = _asString(arguments[0]);
        if (targetUserId == null || targetUserId.isEmpty) return;
        final reason = arguments.length > 1 ? _asString(arguments[1]) : null;
        AppLogger.info("SignalR: Arama reddedildi <- $targetUserId");
        _callRejectedController.add({
          'targetUserId': targetUserId,
          'reason': reason,
        });
      }
    });

    _hubConnection!.on("CallEnded", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final targetUserId = _asString(arguments[0]);
        if (targetUserId == null || targetUserId.isEmpty) return;
        AppLogger.info(
          "SignalR: Arama sonlandÃƒâ€Ã‚Â±rÃƒâ€Ã‚Â±ldÃƒâ€Ã‚Â± <- $targetUserId",
        );
        _callEndedController.add(targetUserId);
      }
    });

    _hubConnection!.on("CallRequestFailed", (arguments) {
      final message = (arguments != null && arguments.isNotEmpty)
          ? (_asString(arguments[0]) ?? 'Arama istegi basarisiz')
          : 'Arama istegi basarisiz';
      AppLogger.warning("SignalR: CallRequestFailed <- $message");
      _callRequestFailedController.add(message);
    });

    _hubConnection!.on("CallActionFailed", (arguments) {
      final message = (arguments != null && arguments.isNotEmpty)
          ? (_asString(arguments[0]) ?? 'Arama islemi basarisiz')
          : 'Arama islemi basarisiz';
      AppLogger.warning("SignalR: CallActionFailed <- $message");
      _callActionFailedController.add(message);
    });

    _hubConnection!.on("SignalDeliveryFailed", (arguments) {
      final phase = (arguments != null && arguments.isNotEmpty)
          ? (_asString(arguments[0]) ?? 'unknown')
          : 'unknown';
      AppLogger.warning("SignalR: SignalDeliveryFailed <- $phase");
      _signalDeliveryFailedController.add(phase);
    });
    _hubConnection!.on("ReceiveOffer", (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      _logIncomingSignal("ReceiveOffer", arguments);

      String? callerId;
      String? sdp;

      if (arguments[0] is Map) {
        final payload = Map<String, dynamic>.from(arguments[0] as Map);
        callerId =
            _readString(payload, const [
              'callerId',
              'CallerId',
              'fromUserId',
              'FromUserId',
            ]) ??
            (arguments.length > 1 ? _asString(arguments[1]) : null);
        sdp = _extractSdp(payload);
        if (sdp == null && arguments.length > 1) {
          sdp = _extractSdp(arguments[1]);
        }
      } else {
        callerId = _asString(arguments[0]);
        if (arguments.length > 1) {
          sdp = _extractSdp(arguments[1]);
        }
      }

      final sdpLen = sdp?.length ?? 0;
      if (callerId == null || callerId.isEmpty || sdp == null || sdp.isEmpty) {
        AppLogger.warning(
          "SignalR: ReceiveOffer invalid payload callerId=$callerId sdpLen=$sdpLen args=$arguments",
        );
        return;
      }

      AppLogger.info(
        "SignalR: SDP Offer alindi <- $callerId (len=$sdpLen head=${_sdpHead(sdp)})",
      );
      _offerController.add({'callerId': callerId, 'sdp': sdp});
    });

    _hubConnection!.on("ReceiveAnswer", (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      _logIncomingSignal("ReceiveAnswer", arguments);

      String? targetUserId;
      String? sdp;

      if (arguments[0] is Map) {
        final payload = Map<String, dynamic>.from(arguments[0] as Map);
        targetUserId =
            _readString(payload, const [
              'targetUserId',
              'TargetUserId',
              'userId',
              'UserId',
              'fromUserId',
              'FromUserId',
            ]) ??
            (arguments.length > 1 ? _asString(arguments[1]) : null);
        sdp = _extractSdp(payload);
        if (sdp == null && arguments.length > 1) {
          sdp = _extractSdp(arguments[1]);
        }
      } else {
        targetUserId = _asString(arguments[0]);
        if (arguments.length > 1) {
          sdp = _extractSdp(arguments[1]);
        }
      }

      final sdpLen = sdp?.length ?? 0;
      if (targetUserId == null ||
          targetUserId.isEmpty ||
          sdp == null ||
          sdp.isEmpty) {
        AppLogger.warning(
          "SignalR: ReceiveAnswer invalid payload targetUserId=$targetUserId sdpLen=$sdpLen args=$arguments",
        );
        return;
      }

      AppLogger.info(
        "SignalR: SDP Answer alindi <- $targetUserId (len=$sdpLen head=${_sdpHead(sdp)})",
      );
      _answerController.add({'targetUserId': targetUserId, 'sdp': sdp});
    });

    _hubConnection!.on("ReceiveIceCandidate", (arguments) {
      if (arguments != null && arguments.length >= 2) {
        final fromUserId = _asString(arguments[0]);
        if (fromUserId == null || fromUserId.isEmpty) return;
        final candidateData = arguments[1];
        AppLogger.info(
          "SignalR: ICE Candidate alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â± <- $fromUserId",
        );

        // candidateData JSON string veya Map olabilir
        Map<String, dynamic> parsed;
        if (candidateData is String) {
          final decoded = jsonDecode(candidateData);
          if (decoded is! Map) return;
          parsed = Map<String, dynamic>.from(decoded);
        } else if (candidateData is Map) {
          parsed = Map<String, dynamic>.from(candidateData);
        } else {
          return;
        }

        final candidate = _asString(parsed['candidate']);
        if (candidate == null || candidate.isEmpty) return;

        _iceCandidateController.add({
          'fromUserId': fromUserId,
          'candidate': candidate,
          'sdpMid': _asString(parsed['sdpMid']),
          'sdpMLineIndex': _asInt(parsed['sdpMLineIndex']),
        });
      }
    });
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null || value is Map || value is List) continue;
      final text = _asString(value);
      if (text != null) return text;
    }
    return null;
  }

  int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      final text = value?.toString().trim() ?? '';
      final parsed = int.tryParse(text);
      if (parsed != null) return parsed;
    }
    return null;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is Map || (value is Iterable && value is! String)) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;
    return text;
  }

  String? _extractSdp(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return _extractSdpFromMap(Map<String, dynamic>.from(value));
    }

    if (value is String) {
      final raw = value;
      final compact = raw.trim();
      if (compact.isEmpty) return null;
      final lower = compact.toLowerCase();
      if (lower == 'null' || lower == 'undefined') return null;

      if (compact.startsWith('"') && compact.endsWith('"')) {
        try {
          final decoded = jsonDecode(compact);
          if (decoded is String) {
            return _normalizeSdpText(decoded);
          }
        } catch (_) {
          // ignore and continue
        }
      }

      if (compact.startsWith('{') && compact.endsWith('}')) {
        try {
          final decoded = jsonDecode(compact);
          if (decoded is Map) {
            return _extractSdpFromMap(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // ignore and continue as plain SDP
        }
      }

      return _normalizeSdpText(raw);
    }

    final text = _asString(value);
    if (text == null) return null;
    return _normalizeSdpText(text);
  }

  String? _extractSdpFromMap(Map<String, dynamic> payload) {
    for (final key in const ['sdp', 'Sdp']) {
      if (!payload.containsKey(key)) continue;
      final directSdp = _extractSdp(payload[key]);
      if (directSdp != null) return directSdp;
    }

    for (final key in const [
      'payload',
      'Payload',
      'data',
      'Data',
      'description',
      'Description',
      'offer',
      'Offer',
      'answer',
      'Answer',
      'sessionDescription',
      'SessionDescription',
    ]) {
      final nested = payload[key];
      final nestedSdp = _extractSdp(nested);
      if (nestedSdp != null) return nestedSdp;
    }

    return null;
  }

  String? _normalizeSdpText(String raw) {
    if (raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;

    var normalized = raw;
    normalized = normalized.replaceAll(r'\u000d\u000a', '\r\n');
    normalized = normalized.replaceAll(r'\r\n', '\r\n');
    if (!normalized.contains('\r\n') && normalized.contains('\n')) {
      normalized = normalized.replaceAll('\n', '\r\n');
    }
    if (!normalized.contains('\r\n') && normalized.contains('\r')) {
      normalized = normalized.replaceAll('\r', '\r\n');
    }

    final head = normalized.trimLeft();
    if (!head.startsWith('v=')) return null;
    return normalized;
  }

  String _sdpHead(String sdp) {
    final flattened = sdp.replaceAll('\r', r'\r').replaceAll('\n', r'\n');
    if (flattened.length <= 40) return flattened;
    return '${flattened.substring(0, 40)}...';
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    final text = value?.toString().trim() ?? '';
    return int.tryParse(text);
  }

  void _logIncomingSignal(String eventName, List<Object?> arguments) {
    final data = arguments.length == 1 ? arguments[0] : arguments;
    AppLogger.error(
      "SIGNAL RECEIVED [$eventName]: $data - Type: ${data.runtimeType}",
    );
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

  // ============================================================
  // P2P CALL SIGNALING ACTIONS
  // ============================================================

  /// Arama isteÃƒâ€Ã…Â¸i gÃƒÆ’Ã‚Â¶nder
  Future<void> sendCallRequest(String targetUserId) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Arama isteÃƒâ€Ã…Â¸i gÃƒÆ’Ã‚Â¶nderilemedi - BAÃƒâ€Ã‚ÂLANTI YOK!",
      );
      return;
    }
    try {
      await _hubConnection!.invoke("SendCallRequest", args: [targetUserId]);
      AppLogger.info(
        "SignalR: Arama isteÃƒâ€Ã…Â¸i gÃƒÆ’Ã‚Â¶nderildi -> $targetUserId",
      );
    } catch (e) {
      AppLogger.error("SignalR: Arama isteÃƒâ€Ã…Â¸i hatasÃƒâ€Ã‚Â±", e);
      rethrow;
    }
  }

  /// AramayÃƒâ€Ã‚Â± kabul et
  Future<void> acceptCall(String targetUserId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("AcceptCall", args: [targetUserId]);
      AppLogger.info("SignalR: Arama kabul edildi -> $targetUserId");
    } catch (e) {
      AppLogger.error("SignalR: Arama kabul hatasÃƒâ€Ã‚Â±", e);
      rethrow;
    }
  }

  /// AramayÃƒâ€Ã‚Â± reddet
  Future<void> rejectCall(String targetUserId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("RejectCall", args: [targetUserId]);
      AppLogger.info("SignalR: Arama reddedildi -> $targetUserId");
    } catch (e) {
      AppLogger.error("SignalR: Arama reddetme hatasÃƒâ€Ã‚Â±", e);
    }
  }

  /// AramayÃƒâ€Ã‚Â± bitir
  Future<void> endCall(String targetUserId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("EndCall", args: [targetUserId]);
      AppLogger.info(
        "SignalR: Arama sonlandÃƒâ€Ã‚Â±rÃƒâ€Ã‚Â±ldÃƒâ€Ã‚Â± -> $targetUserId",
      );
    } catch (e) {
      AppLogger.error("SignalR: Arama sonlandÃƒâ€Ã‚Â±rma hatasÃƒâ€Ã‚Â±", e);
    }
  }

  /// SDP Offer gÃƒÆ’Ã‚Â¶nder
  Future<void> sendOffer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Offer gÃƒÂ¶nderilemedi - BAGLANTI YOK! target=$targetUserId",
      );
      throw StateError('SignalR not connected while sending offer');
    }
    if (sdp.trim().isEmpty) {
      throw ArgumentError.value(sdp, 'sdp', 'Offer SDP is empty');
    }
    AppLogger.info('SignalR: SendOffer contract payload={type,sdp}');
    try {
      await _sendSessionDescriptionSignal(
        methodName: "SendOffer",
        targetUserId: targetUserId,
        type: 'offer',
        sdp: sdp,
      );
      AppLogger.info("SignalR: SDP Offer gÃƒÆ’Ã‚Â¶nderildi -> $targetUserId");
    } catch (e) {
      AppLogger.error("SignalR: Offer gÃƒÆ’Ã‚Â¶nderme hatasÃƒâ€Ã‚Â±", e);
      rethrow;
    }
  }

  /// SDP Answer gÃƒÆ’Ã‚Â¶nder
  Future<void> sendAnswer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Answer gÃƒÂ¶nderilemedi - BAGLANTI YOK! target=$targetUserId",
      );
      throw StateError('SignalR not connected while sending answer');
    }
    if (sdp.trim().isEmpty) {
      throw ArgumentError.value(sdp, 'sdp', 'Answer SDP is empty');
    }
    AppLogger.info('SignalR: SendAnswer contract payload={type,sdp}');
    try {
      await _sendSessionDescriptionSignal(
        methodName: "SendAnswer",
        targetUserId: targetUserId,
        type: 'answer',
        sdp: sdp,
      );
      AppLogger.info("SignalR: SDP Answer gÃƒÆ’Ã‚Â¶nderildi -> $targetUserId");
    } catch (e) {
      AppLogger.error("SignalR: Answer gÃƒÆ’Ã‚Â¶nderme hatasÃƒâ€Ã‚Â±", e);
      rethrow;
    }
  }

  /// SDP Offer/Answer payloadini tek kontratla gonderir.
  Future<void> _sendSessionDescriptionSignal({
    required String methodName,
    required String targetUserId,
    required String type,
    required String sdp,
  }) async {
    final payload = <String, dynamic>{'type': type, 'sdp': sdp};
    AppLogger.info(
      'SignalR: $methodName payload schema=map(type+sdp) sdpLen=${sdp.length}',
    );
    await _hubConnection!.invoke(methodName, args: [targetUserId, payload]);
  }

  /// ICE Candidate gonder
  Future<void> sendIceCandidate(
    String targetUserId,
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    if (!isConnected) return;
    try {
      final candidateData = jsonEncode({
        'candidate': candidate,
        'sdpMid': sdpMid,
        'sdpMLineIndex': sdpMLineIndex,
      });
      await _hubConnection!.invoke(
        "SendIceCandidate",
        args: [targetUserId, candidateData],
      );
    } catch (e) {
      AppLogger.error(
        "SignalR: ICE candidate gÃƒÆ’Ã‚Â¶nderme hatasÃƒâ€Ã‚Â±",
        e,
      );
    }
  }

  /// Backend'den TURN/STUN sunucu bilgilerini al
  /// GET /api/turn/ice-servers
  Future<List<Map<String, dynamic>>> fetchIceServers() async {
    try {
      final token = sharedPreferences.getString('AUTH_TOKEN');
      _resolvedBaseUrl ??= await NetworkModule.getBaseUrl();
      final dio = Dio();
      final response = await dio.get(
        '${_resolvedBaseUrl!}api/turn/ice-servers',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final rawData = response.data;
      final dynamic rawServers = rawData is Map<String, dynamic>
          ? rawData['iceServers'] ?? rawData['data'] ?? rawData['result']
          : null;

      final sourceList = rawServers is List ? rawServers : const <dynamic>[];
      final iceServers = <Map<String, dynamic>>[];

      for (final item in sourceList) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        final rawUrls = map['urls'] ?? map['url'];
        final urls = <String>[];
        if (rawUrls is String && rawUrls.trim().isNotEmpty) {
          urls.add(rawUrls.trim());
        } else if (rawUrls is List) {
          urls.addAll(
            rawUrls
                .map((u) => u?.toString().trim() ?? '')
                .where((u) => u.isNotEmpty),
          );
        }
        if (urls.isEmpty) continue;

        final hasTurn = urls.any(
          (u) => u.startsWith('turn:') || u.startsWith('turns:'),
        );
        final username = map['username']?.toString().trim();
        final credential = map['credential']?.toString().trim();

        if (hasTurn &&
            (username == null ||
                username.isEmpty ||
                credential == null ||
                credential.isEmpty)) {
          AppLogger.warning(
            "SignalR: Invalid TURN server filtered (missing username/credential): $urls",
          );
          continue;
        }

        final normalized = <String, dynamic>{'urls': urls};
        if (username != null && username.isNotEmpty) {
          normalized['username'] = username;
        }
        if (credential != null && credential.isNotEmpty) {
          normalized['credential'] = credential;
        }
        iceServers.add(normalized);
      }

      if (iceServers.isEmpty) {
        AppLogger.warning(
          "SignalR: No valid TURN/STUN from backend, falling back to public STUN",
        );
        return [
          {
            'urls': ['stun:stun.l.google.com:19302'],
          },
        ];
      }

      AppLogger.info(
        "SignalR: TURN credential alÃƒâ€Ã‚Â±ndÃƒâ€Ã‚Â±. Server count: ${iceServers.length}",
      );
      return iceServers;
    } catch (e) {
      AppLogger.error("SignalR: TURN credential alma hatasÃƒâ€Ã‚Â±", e);
      // Fallback: sadece Google STUN
      return [
        {
          'urls': ['stun:stun.l.google.com:19302'],
        },
      ];
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
