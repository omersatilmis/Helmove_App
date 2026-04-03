import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../network/network_module.dart';
import '../utils/app_logger.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import 'communication_baseline_tracker.dart';
import 'models/signalr_payloads.dart';

class SignalRService {
  HubConnection? _hubConnection;
  String? _resolvedBaseUrl;
  final AuthLocalDataSource authLocalDataSource;
  final Dio _dio;
  final CommunicationBaselineTracker _baselineTracker =
      CommunicationBaselineTracker.instance;
  final Random _reconnectJitterRandom = Random();

  /// Race-condition guard: eş zamanlı init() çağrılarını engeller.
  Completer<void>? _initCompleter;
  bool _startupConnectionAllowed = false;

  SignalRService(this.authLocalDataSource, this._dio);

  void enableStartupConnection() {
    _startupConnectionAllowed = true;
  }

  // Broadcast Streams
  final _rideTerminatedController =
      StreamController<RideRealtimePayload>.broadcast();
  final _rideCreatedController =
      StreamController<RideRealtimePayload>.broadcast();
  final _userJoinedController =
      StreamController<VoiceSessionMembershipRealtimePayload>.broadcast();
  final _userLeftController =
      StreamController<VoiceSessionMembershipRealtimePayload>.broadcast();
  final _hostChangedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _groupRideUpdatedController =
      StreamController<RideRealtimePayload>.broadcast();
  final _notificationReceivedController = StreamController<dynamic>.broadcast();
  final _rideLocationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sosAlertController = StreamController<SosAlertPayload>.broadcast();

  // Connection State Stream — BehaviorSubject so new subscribers always get the latest state
  final _connectionStateController = BehaviorSubject<HubConnectionState>.seeded(
    HubConnectionState.Disconnected,
  );
  Stream<HubConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  // ============================================================
  // P2P CALL SIGNALING STREAMS
  // ============================================================
  final _incomingCallController =
      StreamController<CallRequestPayload>.broadcast();
  final _callAcceptedController =
      StreamController<CallAcceptedPayload>.broadcast();
  final _callRejectedController =
      StreamController<CallRejectedPayload>.broadcast();
  final _callEndedController = StreamController<CallEndedPayload>.broadcast();
  final _offerController = StreamController<SdpPayload>.broadcast();
  final _answerController = StreamController<SdpPayload>.broadcast();
  final _iceCandidateController =
      StreamController<IceCandidatePayload>.broadcast();
  final _callRequestFailedController = StreamController<String>.broadcast();
  final _callActionFailedController = StreamController<String>.broadcast();
  final _signalDeliveryFailedController = StreamController<String>.broadcast();
  final _headlessCallRequestController =
      StreamController<CallRequestPayload>.broadcast();
  final _headlessCallAcceptedController =
      StreamController<CallAcceptedPayload>.broadcast();
  final _headlessCallEndedController =
      StreamController<CallEndedPayload>.broadcast();
  final _headlessCallFailedController = StreamController<String>.broadcast();

  Stream<CallRequestPayload> get incomingCallStream =>
      _incomingCallController.stream;
  Stream<CallAcceptedPayload> get callAcceptedStream =>
      _callAcceptedController.stream;
  Stream<CallRejectedPayload> get callRejectedStream =>
      _callRejectedController.stream;
  Stream<CallEndedPayload> get callEndedStream => _callEndedController.stream;
  Stream<SdpPayload> get offerStream => _offerController.stream;
  Stream<SdpPayload> get answerStream => _answerController.stream;
  Stream<IceCandidatePayload> get iceCandidateStream =>
      _iceCandidateController.stream;
  Stream<String> get callRequestFailedStream =>
      _callRequestFailedController.stream;
  Stream<String> get callActionFailedStream =>
      _callActionFailedController.stream;
  Stream<String> get signalDeliveryFailedStream =>
      _signalDeliveryFailedController.stream;
  Stream<CallRequestPayload> get headlessCallRequestStream =>
      _headlessCallRequestController.stream;
  Stream<CallAcceptedPayload> get headlessCallAcceptedStream =>
      _headlessCallAcceptedController.stream;
  Stream<CallEndedPayload> get headlessCallEndedStream =>
      _headlessCallEndedController.stream;

  /// Karşı taraf çevrimdışı olduğunda backend'den gelen sinyal.
  Stream<String> get headlessCallFailedStream =>
      _headlessCallFailedController.stream;

  Stream<RideRealtimePayload> get rideTerminatedStream =>
      _rideTerminatedController.stream;
  Stream<RideRealtimePayload> get rideCreatedStream =>
      _rideCreatedController.stream;
  Stream<VoiceSessionMembershipRealtimePayload> get userJoinedStream =>
      _userJoinedController.stream;
  Stream<VoiceSessionMembershipRealtimePayload> get userLeftStream =>
      _userLeftController.stream;
  Stream<Map<String, dynamic>> get hostChangedStream =>
      _hostChangedController.stream;
  Stream<RideRealtimePayload> get groupRideUpdatedStream =>
      _groupRideUpdatedController.stream;
  Stream<dynamic> get notificationReceivedStream =>
      _notificationReceivedController.stream;
  Stream<Map<String, dynamic>> get rideLocationUpdateStream =>
      _rideLocationUpdateController.stream;
  Stream<SosAlertPayload> get sosAlertStream => _sosAlertController.stream;

  final _voiceSessionRefreshController =
      StreamController<VoiceSessionRefreshRealtimePayload>.broadcast();
  final _userForceRemovedController = StreamController<int>.broadcast();
  final _voiceSessionEndedController =
      StreamController<VoiceSessionEndedRealtimePayload>.broadcast();

  Stream<VoiceSessionRefreshRealtimePayload> get voiceSessionRefreshStream =>
      _voiceSessionRefreshController.stream;
  Stream<int> get userForceRemovedStream => _userForceRemovedController.stream;
  Stream<VoiceSessionEndedRealtimePayload> get voiceSessionEndedStream =>
      _voiceSessionEndedController.stream;

  final _participantStatusUpdatedController =
      StreamController<ParticipantStatusPayload>.broadcast();
  Stream<ParticipantStatusPayload> get participantStatusUpdatedStream =>
      _participantStatusUpdatedController.stream;

  final _userMuteStateController =
      StreamController<UserMuteStatePayload>.broadcast();
  Stream<UserMuteStatePayload> get userMuteStateStream =>
      _userMuteStateController.stream;

  final _userDisconnectedController =
      StreamController<VoiceSessionMembershipRealtimePayload>.broadcast();
  Stream<VoiceSessionMembershipRealtimePayload> get userDisconnectedStream =>
      _userDisconnectedController.stream;

  // Active Voice Session Context
  String? _activeSessionId;
  final Set<String> _joinedVoiceSessionIds = <String>{};

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  bool get isInitializing => _initCompleter != null;
  String? get connectionId => _hubConnection?.connectionId;

  Future<int?> get currentUserId => authLocalDataSource.getUserId();

  List<int> _buildReconnectRetryDelaysMs() {
    const baseDelays = <int>[0, 1000, 2000, 5000, 10000];
    return baseDelays.map((base) {
      if (base == 0) return 0;
      final jitter = _reconnectJitterRandom.nextInt(401) - 200;
      final value = base + jitter;
      return value > 0 ? value : 0;
    }).toList();
  }

  Future<void> init() async {
    if (!_startupConnectionAllowed) {
      AppLogger.info(
        'SignalR init deferred: waiting for bootstrap/auth refresh to complete.',
      );
      return;
    }
    // Guard: Eğer zaten init süreci devam ediyorsa, aynı Future'ı döndür.
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // Zaten bağlıysa tekrar init etme.
    if (_hubConnection != null &&
        _hubConnection!.state != HubConnectionState.Disconnected) {
      return;
    }

    _initCompleter = Completer<void>();
    // Notify listeners that we are trying to connect
    _connectionStateController.add(HubConnectionState.Connecting);

    try {
      final token = await authLocalDataSource.getToken();
      if (token == null || token.trim().isEmpty) {
        AppLogger.warning("SignalR Init Failed: No Token");
        return;
      }

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
                  await authLocalDataSource.getToken() ?? '',
            ),
          )
          .withAutomaticReconnect(retryDelays: _buildReconnectRetryDelaysMs())
          .build();

      AppLogger.info("SignalR: Registering event handlers...");
      _registerEventHandlers();

      // Hook into lifecycle events
      _hubConnection!.onreconnecting(({error}) {
        _trackSignalREvent('SignalR.Reconnecting');
        AppLogger.warning("SignalR: Reconnecting... $error");
        _joinedVoiceSessionIds.clear();
        _activeSessionId = null;
        _connectionStateController.add(HubConnectionState.Reconnecting);
      });

      _hubConnection!.onreconnected(({connectionId}) {
        _trackSignalREvent('SignalR.Reconnected');
        AppLogger.info("SignalR: Reconnected! connectionId=$connectionId");
        _connectionStateController.add(HubConnectionState.Connected);
      });

      _hubConnection!.onclose(({error}) {
        _trackSignalREvent('SignalR.Closed');
        AppLogger.warning("SignalR: Connection closed. $error");
        _joinedVoiceSessionIds.clear();
        _activeSessionId = null;
        _connectionStateController.add(HubConnectionState.Disconnected);
      });

      await start();

      if (_hubConnection?.state == HubConnectionState.Connected) {
        _connectionStateController.add(HubConnectionState.Connected);
      } else {
        AppLogger.warning(
          "SignalR: init() finished but state is ${_hubConnection?.state}",
        );
        _connectionStateController.add(HubConnectionState.Disconnected);
      }
    } catch (e) {
      AppLogger.error("SignalR Init Error", e);
      _connectionStateController.add(HubConnectionState.Disconnected);
    } finally {
      _initCompleter?.complete();
      _initCompleter = null;
    }
  }

  void _trackSignalREvent(String eventName) {
    _baselineTracker.recordSignalREvent(eventName);
  }

  void _registerEventHandlers() {
    if (_hubConnection == null) return;

    _hubConnection!.on("UserJoinedVoiceSession", (arguments) {
      _trackSignalREvent('UserJoinedVoiceSession');
      final payload = _parseVoiceSessionMembershipRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: User Joined Voice Session -> ${payload.userId} (Session: ${payload.sessionId}, Version: ${payload.version ?? '-'})",
      );
      _userJoinedController.add(payload);
    });

    _hubConnection!.on("UserLeftVoiceSession", (arguments) {
      _trackSignalREvent('UserLeftVoiceSession');
      final payload = _parseVoiceSessionMembershipRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: User Left Voice Session -> ${payload.userId} (Session: ${payload.sessionId}, Version: ${payload.version ?? '-'})",
      );
      _userLeftController.add(payload);
    });

    _hubConnection!.on("RideCreated", (arguments) {
      _trackSignalREvent('RideCreated');
      final payload = _parseRideRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: Ride Created Event Received -> Ride: ${payload.rideId}, Version: ${payload.version ?? '-'}",
      );
      _rideCreatedController.add(payload);
    });

    _hubConnection!.on("ReceiveRideLocationUpdate", (arguments) {
      _trackSignalREvent('ReceiveRideLocationUpdate');
      if (arguments != null && arguments.length >= 2) {
        final userId = _asString(arguments[0]);
        if (userId == null || userId.isEmpty) return;
        final data = arguments[1];
        if (data is Map) {
          _rideLocationUpdateController.add({
            'userId': userId,
            ...Map<String, dynamic>.from(data),
          });
        } else {
          // Fallback if data structure is different, or wrap it
          _rideLocationUpdateController.add({'userId': userId, 'data': data});
        }
      }
    });

    _hubConnection!.on("RideTerminated", (arguments) {
      _trackSignalREvent('RideTerminated');
      final payload = _parseRideRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: Ride Terminated -> Ride: ${payload.rideId}, Version: ${payload.version ?? '-'}",
      );
      _rideTerminatedController.add(payload);
    });

    _hubConnection!.on("HostChanged", (arguments) {
      _trackSignalREvent('HostChanged');
      if (arguments != null && arguments.isNotEmpty) {
        if (arguments[0] is! Map) return;
        final data = Map<String, dynamic>.from(arguments[0] as Map);
        AppLogger.info("SignalR: Host Changed -> $data");
        _hostChangedController.add(data);
      }
    });

    _hubConnection!.on("VoiceSessionRefresh", (arguments) {
      _trackSignalREvent('VoiceSessionRefresh');
      final payload = _parseVoiceSessionRefreshRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: VoiceSession Refresh -> Session: ${payload.sessionId}, Version: ${payload.version ?? '-'}",
      );
      _voiceSessionRefreshController.add(payload);
    });

    _hubConnection!.on("UserForceRemoved", (arguments) {
      _trackSignalREvent('UserForceRemoved');
      if (arguments == null || arguments.isEmpty) return;
      int? sessionId;
      if (arguments[0] is Map) {
        final payload = Map<String, dynamic>.from(arguments[0] as Map);
        final data = payload['data'];
        if (data is Map) {
          final nested = Map<String, dynamic>.from(data);
          sessionId = _readInt(nested, const ['sessionId', 'SessionId']);
        }
        sessionId ??= _readInt(payload, const ['sessionId', 'SessionId']);
      } else {
        sessionId = _asInt(arguments[0]);
      }
      if (sessionId == null) return;
      AppLogger.info("SignalR: User Force Removed -> $sessionId");
      _userForceRemovedController.add(sessionId);
    });

    _hubConnection!.on("VoiceSessionEnded", (arguments) {
      _trackSignalREvent('VoiceSessionEnded');
      final payload = _parseVoiceSessionEndedRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: VoiceSession Ended -> Session: ${payload.sessionId}, Version: ${payload.version ?? '-'}, Reason: ${payload.reason ?? '-'}",
      );
      _voiceSessionEndedController.add(payload);
    });

    _hubConnection!.on("GroupRideUpdated", (arguments) {
      _trackSignalREvent('GroupRideUpdated');
      final payload = _parseRideRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: GroupRide Updated -> Ride: ${payload.rideId}, Version: ${payload.version ?? '-'}",
      );
      _groupRideUpdatedController.add(payload);
    });

    _hubConnection!.on("ReceiveNotification", (arguments) {
      _trackSignalREvent('ReceiveNotification');
      if (arguments != null && arguments.isNotEmpty) {
        final notification = arguments[0];
        AppLogger.info("SignalR: Received Notification -> $notification");
        _notificationReceivedController.add(notification);
      }
    });

    _hubConnection!.on("ReceiveSosAlert", (arguments) {
      _trackSignalREvent('ReceiveSosAlert');
      if (arguments == null || arguments.isEmpty) return;
      final payload = SosAlertPayload.tryParse(arguments[0]);
      if (payload == null) return;
      AppLogger.warning(
        "SignalR: SOS Alert -> Ride:${payload.groupRideId} Sender:${payload.senderId}",
      );
      _sosAlertController.add(payload);
    });

    _hubConnection!.on("ParticipantStatusUpdated", (arguments) {
      _trackSignalREvent('ParticipantStatusUpdated');
      if (arguments != null && arguments.isNotEmpty) {
        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          _participantStatusUpdatedController.add(
            ParticipantStatusPayload.fromMap(payload),
          );
        }
      }
    });

    _hubConnection!.on("UserMuteStateChanged", (arguments) {
      _trackSignalREvent('UserMuteStateChanged');
      if (arguments != null && arguments.isNotEmpty) {
        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          _userMuteStateController.add(UserMuteStatePayload.fromMap(payload));
        }
      }
    });

    _hubConnection!.on("UserDisconnectedFromVoiceSession", (arguments) {
      _trackSignalREvent('UserDisconnectedFromVoiceSession');
      final payload = _parseVoiceSessionMembershipRealtimePayload(arguments);
      if (payload == null) return;
      AppLogger.info(
        "SignalR: User Disconnected From Voice Session -> ${payload.userId} (Session: ${payload.sessionId}, Version: ${payload.version ?? '-'})",
      );
      _userDisconnectedController.add(payload);
    });

    // ============================================================
    // P2P CALL SIGNALING HANDLERS
    // ============================================================

    _hubConnection!.on("ReceiveCallRequest", (arguments) {
      _trackSignalREvent('ReceiveCallRequest');
      if (arguments != null && arguments.isNotEmpty) {
        AppLogger.info("SignalR: ReceiveCallRequest RAW ARGS: $arguments");

        String? callerId;
        String? callerDisplayName;
        int? callId;

        // Backend can send arguments as a single object or positional args
        if (arguments[0] is Map) {
          final data = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            data,
            'ReceiveCallRequest',
            allowMissingMetadata: true,
          )) {
            return;
          }
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
        _incomingCallController.add(
          CallRequestPayload(
            callerId: callerId,
            callerDisplayName: callerDisplayName,
            callId: callId,
          ),
        );
      } else {
        AppLogger.warning(
          "SignalR: ReceiveCallRequest received but arguments are null or empty!",
        );
      }
    });

    _hubConnection!.on("CallAccepted", (arguments) {
      _trackSignalREvent('CallAccepted');
      if (arguments != null && arguments.isNotEmpty) {
        String? acceptedByUserId;
        String? targetUserId;

        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'CallAccepted',
            allowMissingMetadata: true,
          )) {
            return;
          }
          acceptedByUserId =
              _readString(payload, const [
                'acceptedByUserId',
                'AcceptedByUserId',
                'callerId',
                'CallerId',
                'userId',
                'UserId',
              ]) ??
              '';
          targetUserId = _readString(payload, const [
            'targetUserId',
            'TargetUserId',
            'receiverId',
            'ReceiverId',
          ]);
        } else {
          acceptedByUserId = _asString(arguments[0]);
          targetUserId = arguments.length > 1 ? _asString(arguments[1]) : null;
        }

        if (acceptedByUserId == null || acceptedByUserId.isEmpty) return;
        AppLogger.info(
          "SignalR: Arama kabul edildi <- acceptedBy=$acceptedByUserId target=${targetUserId ?? '-'}",
        );
        _callAcceptedController.add(
          CallAcceptedPayload(
            actorId: acceptedByUserId,
            targetUserId: targetUserId,
          ),
        );
      }
    });

    _hubConnection!.on("CallRejected", (arguments) {
      _trackSignalREvent('CallRejected');
      if (arguments != null && arguments.isNotEmpty) {
        String? rejectedByUserId;
        String? targetUserId;
        String? reason;

        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'CallRejected',
            allowMissingMetadata: true,
          )) {
            return;
          }
          rejectedByUserId =
              _readString(payload, const [
                'rejectedByUserId',
                'RejectedByUserId',
                'callerId',
                'CallerId',
                'userId',
                'UserId',
              ]) ??
              '';
          targetUserId = _readString(payload, const [
            'targetUserId',
            'TargetUserId',
            'receiverId',
            'ReceiverId',
          ]);
          reason = _readString(payload, const ['reason', 'Reason']);
        } else {
          rejectedByUserId = _asString(arguments[0]);
          targetUserId = arguments.length > 1 ? _asString(arguments[1]) : null;
          reason = arguments.length > 2 ? _asString(arguments[2]) : null;
        }

        if (rejectedByUserId == null || rejectedByUserId.isEmpty) return;
        AppLogger.info(
          "SignalR: Arama reddedildi <- rejectedBy=$rejectedByUserId target=${targetUserId ?? '-'}",
        );
        _callRejectedController.add(
          CallRejectedPayload(
            actorId: rejectedByUserId,
            targetUserId: targetUserId,
            reason: reason,
          ),
        );
      }
    });

    _hubConnection!.on("CallEnded", (arguments) {
      _trackSignalREvent('CallEnded');
      if (arguments != null && arguments.isNotEmpty) {
        String? endedByUserId;
        String? targetUserId;

        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'CallEnded',
            allowMissingMetadata: true,
          )) {
            return;
          }
          endedByUserId =
              _readString(payload, const [
                'endedByUserId',
                'EndedByUserId',
                'callerId',
                'CallerId',
                'userId',
                'UserId',
              ]) ??
              '';
          targetUserId = _readString(payload, const [
            'targetUserId',
            'TargetUserId',
            'receiverId',
            'ReceiverId',
          ]);
        } else {
          endedByUserId = _asString(arguments[0]);
          targetUserId = arguments.length > 1 ? _asString(arguments[1]) : null;
        }

        if (endedByUserId == null || endedByUserId.isEmpty) return;
        AppLogger.info(
          "SignalR: Arama sonlandirildi <- endedBy=$endedByUserId target=${targetUserId ?? '-'}",
        );
        _callEndedController.add(
          CallEndedPayload(
            actorId: endedByUserId,
            targetUserId: targetUserId,
            reason: null, // Basic CallEnded doesn't usually carry reason
          ),
        );
      }
    });

    _hubConnection!.on("CallRequestFailed", (arguments) {
      _trackSignalREvent('CallRequestFailed');
      String message = 'Arama istegi basarisiz';
      if (arguments != null && arguments.isNotEmpty) {
        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (_hasRequiredRealtimeMetadata(payload, 'CallRequestFailed')) {
            message =
                _readString(payload, const ['message', 'Message']) ?? message;
          }
        } else {
          message = _asString(arguments[0]) ?? message;
        }
      }
      AppLogger.warning("SignalR: CallRequestFailed <- $message");
      _callRequestFailedController.add(message);
    });

    _hubConnection!.on("CallActionFailed", (arguments) {
      _trackSignalREvent('CallActionFailed');
      String message = 'Arama islemi basarisiz';
      if (arguments != null && arguments.isNotEmpty) {
        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (_hasRequiredRealtimeMetadata(payload, 'CallActionFailed')) {
            message =
                _readString(payload, const ['message', 'Message']) ?? message;
          }
        } else {
          message = _asString(arguments[0]) ?? message;
        }
      }
      AppLogger.warning("SignalR: CallActionFailed <- $message");
      _callActionFailedController.add(message);
    });

    _hubConnection!.on("SignalDeliveryFailed", (arguments) {
      _trackSignalREvent('SignalDeliveryFailed');
      String phase = 'unknown';
      if (arguments != null && arguments.isNotEmpty) {
        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (_hasRequiredRealtimeMetadata(payload, 'SignalDeliveryFailed')) {
            phase =
                _readString(payload, const ['phase', 'Phase', 'reason']) ??
                phase;
          }
        } else {
          phase = _asString(arguments[0]) ?? phase;
        }
      }
      AppLogger.warning("SignalR: SignalDeliveryFailed <- $phase");
      _signalDeliveryFailedController.add(phase);
    });
    _hubConnection!.on("ReceiveOffer", (arguments) {
      _trackSignalREvent('ReceiveOffer');
      if (arguments == null || arguments.isEmpty) return;
      _logIncomingSignal("ReceiveOffer", arguments);

      String? callerId;
      String? sdp;

      if (arguments[0] is Map) {
        final payload = Map<String, dynamic>.from(arguments[0] as Map);
        if (!_hasRequiredRealtimeMetadata(
          payload,
          'ReceiveOffer',
          allowMissingMetadata: true,
        )) {
          return;
        }
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
      _offerController.add(SdpPayload(userId: callerId, sdp: sdp));
    });

    _hubConnection!.on("ReceiveAnswer", (arguments) {
      _trackSignalREvent('ReceiveAnswer');
      if (arguments == null || arguments.isEmpty) return;
      _logIncomingSignal("ReceiveAnswer", arguments);

      String? targetUserId;
      String? sdp;

      if (arguments[0] is Map) {
        final payload = Map<String, dynamic>.from(arguments[0] as Map);
        if (!_hasRequiredRealtimeMetadata(
          payload,
          'ReceiveAnswer',
          allowMissingMetadata: true,
        )) {
          return;
        }
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
      _answerController.add(SdpPayload(userId: targetUserId, sdp: sdp));
    });

    _hubConnection!.on("ReceiveIceCandidate", (arguments) {
      _trackSignalREvent('ReceiveIceCandidate');
      if (arguments != null && arguments.isNotEmpty) {
        String? fromUserId;
        dynamic candidateData;
        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'ReceiveIceCandidate',
            allowMissingMetadata: true,
          )) {
            return;
          }
          fromUserId = _readString(payload, const ['fromUserId', 'FromUserId']);
          candidateData = payload['candidate'];
        } else {
          if (arguments.length < 2) return;
          fromUserId = _asString(arguments[0]);
          candidateData = arguments[1];
        }
        if (fromUserId == null || fromUserId.isEmpty) return;
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

        _iceCandidateController.add(
          IceCandidatePayload(
            fromUserId: fromUserId,
            candidate: candidate,
            sdpMid: _asString(parsed['sdpMid']),
            sdpMLineIndex: _asInt(parsed['sdpMLineIndex']),
          ),
        );
      }
    });

    // [ICE-BATCH] Tek mesajda gelen tüm ICE candidate'leri bireysel event olarak emit et.
    // Engine tarafında mevcut _iceSub listener'ı değişmeden çalışır; batch tamamen şeffaf.
    _hubConnection!.on('ReceiveIceCandidatesBatch', (arguments) {
      _trackSignalREvent('ReceiveIceCandidatesBatch');
      if (arguments == null || arguments.isEmpty) return;

      String? fromUserId;
      dynamic rawCandidates;

      if (arguments[0] is Map) {
        final payload = Map<String, dynamic>.from(arguments[0] as Map);
        if (!_hasRequiredRealtimeMetadata(
          payload,
          'ReceiveIceCandidatesBatch',
          allowMissingMetadata: true,
        )) {
          return;
        }
        fromUserId = _readString(payload, const ['fromUserId', 'FromUserId']);
        rawCandidates = payload['candidates'];
      } else {
        if (arguments.length < 2) return;
        fromUserId = _asString(arguments[0]);
        rawCandidates = arguments[1];
      }

      if (fromUserId == null || fromUserId.isEmpty) return;

      List<dynamic> candidateList;
      if (rawCandidates is String) {
        final decoded = jsonDecode(rawCandidates);
        if (decoded is! List) return;
        candidateList = decoded;
      } else if (rawCandidates is List) {
        candidateList = rawCandidates;
      } else {
        return;
      }

      AppLogger.info(
        'SignalR: ICE batch alındı <- $fromUserId (${candidateList.length} candidate)',
      );

      for (final item in candidateList) {
        final Map<String, dynamic> parsed;
        if (item is String) {
          final decoded = jsonDecode(item);
          if (decoded is! Map) continue;
          parsed = Map<String, dynamic>.from(decoded);
        } else if (item is Map) {
          parsed = Map<String, dynamic>.from(item);
        } else {
          continue;
        }

        final candidate = _asString(parsed['candidate']);
        if (candidate == null || candidate.isEmpty) continue;

        _iceCandidateController.add(
          IceCandidatePayload(
            fromUserId: fromUserId,
            candidate: candidate,
            sdpMid: _asString(parsed['sdpMid']),
            sdpMLineIndex: _asInt(parsed['sdpMLineIndex']),
          ),
        );
      }
    });

    // [ICE-BATCH] Tek mesajda gelen tüm ICE candidate'leri bireysel event olarak emit et.
    // Engine tarafında mevcut _iceSub listener'ı değişmeden çalışır; batch tamamen şeffaf.
    _hubConnection!.on('ReceiveIceCandidatesBatch', (arguments) {
      _trackSignalREvent('ReceiveIceCandidatesBatch');
      if (arguments == null || arguments.isEmpty) return;

      String? fromUserId;
      dynamic rawCandidates;

      if (arguments[0] is Map) {
        final payload = Map<String, dynamic>.from(arguments[0] as Map);
        if (!_hasRequiredRealtimeMetadata(
          payload,
          'ReceiveIceCandidatesBatch',
          allowMissingMetadata: true,
        )) {
          return;
        }
        fromUserId = _readString(payload, const ['fromUserId', 'FromUserId']);
        rawCandidates = payload['candidates'];
      } else {
        if (arguments.length < 2) return;
        fromUserId = _asString(arguments[0]);
        rawCandidates = arguments[1];
      }

      if (fromUserId == null || fromUserId.isEmpty) return;

      List<dynamic> candidateList;
      if (rawCandidates is String) {
        final decoded = jsonDecode(rawCandidates);
        if (decoded is! List) return;
        candidateList = decoded;
      } else if (rawCandidates is List) {
        candidateList = rawCandidates;
      } else {
        return;
      }

      AppLogger.info(
        'SignalR: ICE batch alındı <- $fromUserId (${candidateList.length} candidate)',
      );

      for (final item in candidateList) {
        final Map<String, dynamic> parsed;
        if (item is String) {
          final decoded = jsonDecode(item);
          if (decoded is! Map) continue;
          parsed = Map<String, dynamic>.from(decoded);
        } else if (item is Map) {
          parsed = Map<String, dynamic>.from(item);
        } else {
          continue;
        }

        final candidate = _asString(parsed['candidate']);
        if (candidate == null || candidate.isEmpty) continue;

        _iceCandidateController.add(
          IceCandidatePayload(
            fromUserId: fromUserId,
            candidate: candidate,
            sdpMid: _asString(parsed['sdpMid']),
            sdpMLineIndex: _asInt(parsed['sdpMLineIndex']),
          ),
        );
      }
    });

    _hubConnection!.on("ReceiveHeadlessCallRequest", (arguments) {
      _trackSignalREvent('ReceiveHeadlessCallRequest');
      if (arguments != null && arguments.isNotEmpty) {
        String? callerId;

        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'ReceiveHeadlessCallRequest',
            allowMissingMetadata: true,
          )) {
            return;
          }
          callerId = _readActorId(payload);
        } else {
          callerId = _asString(arguments[0]);
        }

        if (callerId == null || callerId.isEmpty) return;

        AppLogger.info(
          "SignalR: ReceiveHeadlessCallRequest <- actorId=$callerId",
        );
        _headlessCallRequestController.add(
          CallRequestPayload(callerId: callerId),
        );
      }
    });

    _hubConnection!.on("HeadlessCallAccepted", (arguments) {
      _trackSignalREvent('HeadlessCallAccepted');
      if (arguments != null && arguments.isNotEmpty) {
        String? actorId;
        String? targetUserId;

        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'HeadlessCallAccepted',
            allowMissingMetadata: true,
          )) {
            return;
          }
          actorId = _readActorId(payload);
          targetUserId = _readString(payload, const [
            'targetUserId',
            'TargetUserId',
            'receiverId',
            'ReceiverId',
          ]);
        } else {
          actorId = _asString(arguments[0]);
          targetUserId = arguments.length > 1 ? _asString(arguments[1]) : null;
        }

        if (actorId == null || actorId.isEmpty) return;

        AppLogger.info(
          "SignalR: HeadlessCallAccepted <- actorId=$actorId target=${targetUserId ?? '-'}",
        );
        _headlessCallAcceptedController.add(
          CallAcceptedPayload(actorId: actorId, targetUserId: targetUserId),
        );
      }
    });

    _hubConnection!.on("HeadlessCallEnded", (arguments) {
      _trackSignalREvent('HeadlessCallEnded');
      if (arguments != null && arguments.isNotEmpty) {
        String? actorId;
        String? targetUserId;
        String? reason;

        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'HeadlessCallEnded',
            allowMissingMetadata: true,
          )) {
            return;
          }
          actorId = _readActorId(payload);
          targetUserId = _readString(payload, const [
            'targetUserId',
            'TargetUserId',
            'receiverId',
            'ReceiverId',
          ]);
          reason = _readString(payload, const ['reason', 'Reason']);
        } else {
          actorId = _asString(arguments[0]);
          targetUserId = arguments.length > 1 ? _asString(arguments[1]) : null;
          reason = arguments.length > 2 ? _asString(arguments[2]) : null;
        }

        if (actorId == null || actorId.isEmpty) return;

        AppLogger.info(
          "SignalR: HeadlessCallEnded <- actorId=$actorId target=${targetUserId ?? '-'} reason=${reason ?? '-'}",
        );
        _headlessCallEndedController.add(
          CallEndedPayload(
            actorId: actorId,
            targetUserId: targetUserId,
            reason: reason,
          ),
        );
      }
    });

    // Karşı taraf offline → backend HeadlessCallFailed gönderiyor
    _hubConnection!.on("HeadlessCallFailed", (arguments) {
      _trackSignalREvent('HeadlessCallFailed');
      if (arguments != null && arguments.isNotEmpty) {
        String? targetUserId;
        if (arguments[0] is Map) {
          final payload = Map<String, dynamic>.from(arguments[0] as Map);
          if (!_hasRequiredRealtimeMetadata(
            payload,
            'HeadlessCallFailed',
            allowMissingMetadata: true,
          )) {
            return;
          }
          targetUserId = _readString(payload, const [
            'targetUserId',
            'TargetUserId',
          ]);
        } else {
          targetUserId = _asString(arguments[0]);
        }
        if (targetUserId != null && targetUserId.isNotEmpty) {
          AppLogger.warning(
            "SignalR: HeadlessCallFailed <- target=$targetUserId (offline)",
          );
          _headlessCallFailedController.add(targetUserId);
        }
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

  String? _readActorId(Map<String, dynamic> data) {
    return _readString(data, const [
      'actorId',
      'ActorId',
      'acceptedBy',
      'AcceptedBy',
      'acceptedByUserId',
      'AcceptedByUserId',
      'rejectedBy',
      'RejectedBy',
      'rejectedByUserId',
      'RejectedByUserId',
      'endedBy',
      'EndedBy',
      'endedByUserId',
      'EndedByUserId',
      'callerId',
      'CallerId',
      'fromUserId',
      'FromUserId',
      'userId',
      'UserId',
    ]);
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

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    final text = _asString(value);
    if (text == null || text.length < 2) return null;
    if (!text.startsWith('{') || !text.endsWith('}')) return null;

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // ignore parse errors and fallback to positional format
    }
    return null;
  }

  bool _hasRequiredRealtimeMetadata(
    Map<String, dynamic> payload,
    String event, {
    bool allowMissingMetadata = false,
  }) {
    final eventId = _readString(payload, const ['eventId', 'EventId']);
    final version = _readInt(payload, const ['version', 'Version']);
    final occurredAt = _readString(payload, const [
      'occurredAtUtc',
      'OccurredAtUtc',
    ]);
    if (eventId == null ||
        eventId.isEmpty ||
        version == null ||
        occurredAt == null) {
      if (allowMissingMetadata) {
        AppLogger.warning(
          'SignalR: $event metadata missing (legacy payload accepted).',
        );
        return true;
      }
      AppLogger.warning(
        'SignalR: $event dropped (missing metadata eventId/version/occurredAtUtc).',
      );
      return false;
    }
    return true;
  }

  RideRealtimePayload? _parseRideRealtimePayload(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return null;

    final mapped = _asMap(arguments[0]);
    if (mapped != null) {
      if (!_hasRequiredRealtimeMetadata(mapped, 'RideRealtimePayload')) {
        return null;
      }
      final payload = RideRealtimePayload.fromMap(mapped);
      if (payload.rideId > 0 &&
          payload.eventId != null &&
          payload.occurredAtUtc != null) {
        return payload;
      }
    }

    final rideId = _asInt(arguments[0]);
    if (rideId == null || rideId <= 0) return null;
    final sessionId = arguments.length > 1 ? _asInt(arguments[1]) : null;
    final version = arguments.length > 2 ? _asInt(arguments[2]) : null;
    return RideRealtimePayload(
      rideId: rideId,
      sessionId: sessionId,
      version: version,
      eventId: null,
      occurredAtUtc: null,
    );
  }

  VoiceSessionRefreshRealtimePayload? _parseVoiceSessionRefreshRealtimePayload(
    List<Object?>? arguments,
  ) {
    if (arguments == null || arguments.isEmpty) return null;

    final mapped = _asMap(arguments[0]);
    if (mapped != null) {
      if (!_hasRequiredRealtimeMetadata(
        mapped,
        'VoiceSessionRefreshRealtimePayload',
      )) {
        return null;
      }
      final payload = VoiceSessionRefreshRealtimePayload.fromMap(mapped);
      if (payload.sessionId > 0 &&
          payload.eventId != null &&
          payload.occurredAtUtc != null) {
        return payload;
      }
    }

    final sessionId = _asInt(arguments[0]);
    if (sessionId == null || sessionId <= 0) return null;
    final version = arguments.length > 1 ? _asInt(arguments[1]) : null;
    return VoiceSessionRefreshRealtimePayload(
      sessionId: sessionId,
      version: version,
      eventId: null,
      occurredAtUtc: null,
    );
  }

  VoiceSessionMembershipRealtimePayload?
  _parseVoiceSessionMembershipRealtimePayload(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return null;

    final mapped = _asMap(arguments[0]);
    if (mapped != null) {
      if (!_hasRequiredRealtimeMetadata(
        mapped,
        'VoiceSessionMembershipRealtimePayload',
      )) {
        return null;
      }
      final payload = VoiceSessionMembershipRealtimePayload.fromMap(mapped);
      if (payload.userId.isNotEmpty &&
          payload.sessionId > 0 &&
          payload.eventId != null &&
          payload.occurredAtUtc != null) {
        return payload;
      }
    }

    final userId = _asString(arguments[0]);
    if (userId == null || userId.isEmpty) return null;

    final sessionId =
        (arguments.length > 1 ? _asInt(arguments[1]) : null) ??
        _asInt(_activeSessionId);
    if (sessionId == null || sessionId <= 0) return null;

    final version = arguments.length > 2 ? _asInt(arguments[2]) : null;
    return VoiceSessionMembershipRealtimePayload(
      userId: userId,
      sessionId: sessionId,
      version: version,
      eventId: null,
      occurredAtUtc: null,
    );
  }

  VoiceSessionEndedRealtimePayload? _parseVoiceSessionEndedRealtimePayload(
    List<Object?>? arguments,
  ) {
    if (arguments == null || arguments.isEmpty) return null;

    final mapped = _asMap(arguments[0]);
    if (mapped != null) {
      if (!_hasRequiredRealtimeMetadata(
        mapped,
        'VoiceSessionEndedRealtimePayload',
        allowMissingMetadata: true,
      )) {
        return null;
      }
      
      // Data field is sometimes flattened or nested, map directly or extract data
      Map<String, dynamic> dataMap = mapped;
      if (mapped.containsKey('data') && mapped['data'] is Map) {
         final nested = Map<String, dynamic>.from(mapped['data']);
         dataMap = {...mapped, ...nested};
      }
      
      final payload = VoiceSessionEndedRealtimePayload.fromMap(dataMap);
      if (payload.sessionId > 0) {
        return payload;
      }
    }

    final sessionId = _asInt(arguments[0]);
    if (sessionId == null || sessionId <= 0) return null;
    final version = arguments.length > 1 ? _asInt(arguments[1]) : null;
    return VoiceSessionEndedRealtimePayload(
      sessionId: sessionId,
      version: version,
      eventId: null,
      occurredAtUtc: null,
    );
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
        rethrow;
      }
    }
  }

  Future<void> stop() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
      _joinedVoiceSessionIds.clear();
      _activeSessionId = null;
      // Close local streams if needed, or keep open if service is singleton
      // _rideTerminatedController.close(); // Careful with singletons
      AppLogger.info("SignalR Connection Stopped");
    }
  }

  // --- Actions ---

  Future<void> joinVoiceSessionGroup(String sessionId) async {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) return;
    if (!isConnected) return;
    if (_joinedVoiceSessionIds.contains(normalizedSessionId)) {
      _activeSessionId = normalizedSessionId;
      AppLogger.info(
        "JoinVoiceSessionGroup skipped (already joined): $normalizedSessionId",
      );
      return;
    }
    try {
      await _hubConnection!.invoke(
        "JoinVoiceSessionGroup",
        args: [normalizedSessionId],
      );
      _joinedVoiceSessionIds.add(normalizedSessionId);
      _activeSessionId = normalizedSessionId;
      AppLogger.info("Joined Voice Session Group: $normalizedSessionId");
    } catch (e) {
      AppLogger.error("Error joining voice session group", e);
    }
  }

  Future<void> leaveVoiceSessionGroup(String sessionId) async {
    final normalizedSessionId = sessionId.trim();
    if (normalizedSessionId.isEmpty) return;
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke(
        "LeaveVoiceSessionGroup",
        args: [normalizedSessionId],
      );
      _joinedVoiceSessionIds.remove(normalizedSessionId);
      if (_activeSessionId == normalizedSessionId) {
        _activeSessionId = null;
      }
      AppLogger.info("Left Voice Session Group: $normalizedSessionId");
    } catch (e) {
      AppLogger.error("Error leaving voice session group", e);
    }
  }

  Future<void> joinRideGroup(String rideId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("JoinRideGroup", args: [rideId]);
      AppLogger.info("Joined Ride Group: $rideId");
    } catch (e) {
      AppLogger.error("Error joining ride group", e);
    }
  }

  Future<void> leaveRideGroup(String rideId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("LeaveRideGroup", args: [rideId]);
      AppLogger.info("Left Ride Group: $rideId");
    } catch (e) {
      AppLogger.error("Error leaving ride group", e);
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
      // İYİLEŞTİRME: Hata durumunda UI'ın sonsuz beklemesini önlemek için hata fırlatmak yerine
      // controller üzerinden hata mesajı yayınlayabiliriz. Ancak mevcut yapıda rethrow
      // UI tarafında try-catch ile yakalanıyorsa uygundur.
      // Profesyonel kullanımda buraya bir "Retry" mekanizması eklenebilir.
      _callRequestFailedController.add("Bağlantı hatası: Arama başlatılamadı.");
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

  /// Headless Arama İsteği (RTC Orchestrator için)
  Future<void> sendHeadlessCallRequest(String targetUserId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke(
        "SendHeadlessCallRequest",
        args: [targetUserId],
      );
      AppLogger.info(
        "SignalR: Headless arama isteği gönderildi -> $targetUserId",
      );
    } catch (e) {
      AppLogger.error("SignalR: Headless arama hatası", e);
    }
  }

  Future<void> acceptHeadlessCall(String targetUserId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("AcceptHeadlessCall", args: [targetUserId]);
    } catch (e) {
      AppLogger.error("SignalR: Headless kabul hatası", e);
    }
  }

  Future<void> endHeadlessCall(String targetUserId) async {
    if (!isConnected) return;
    try {
      await _hubConnection!.invoke("EndHeadlessCall", args: [targetUserId]);
    } catch (e) {
      AppLogger.error("SignalR: Headless sonlandırma hatası", e);
    }
  }

  /// SDP Offer gÃƒÆ’Ã‚Â¶nder
  Future<void> sendOffer(String targetUserId, String sdp) async {
    if (!isConnected) {
      AppLogger.warning(
        "SignalR: Offer gonderilemedi - BAGLANTI YOK! Fallback (HTTP) deneniyor... target=$targetUserId",
      );
      return await _fallbackSendSignal('SendOffer', targetUserId, 'offer', sdp);
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
        "SignalR: Answer gonderilemedi - BAGLANTI YOK! Fallback (HTTP) deneniyor... target=$targetUserId",
      );
      return await _fallbackSendSignal(
        'SendAnswer',
        targetUserId,
        'answer',
        sdp,
      );
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
  // [NEW] Fallback Sinyallesme (HTTP POST via Dio)
  Future<void> _fallbackSendSignal(
    String method,
    String targetUserId,
    String type,
    String sdp,
  ) async {
    try {
      final payload = {'type': type, 'sdp': sdp};

      // Backend'de "/api/communication/fallback" veya benzer bir endpoint oldugu varsayilir.
      // Eger yoksa 404 yiyecektir ancak sistem cokertecek throw atilmaz, gracefull fallback saglar.
      await _dio.post(
        'api/communication/fallback',
        data: {
          'method': method,
          'targetUserId': targetUserId,
          'payload': payload,
        },
      );
      AppLogger.info(
        "SignalR: Fallback HTTP Sinyali basariyla iletildi -> $targetUserId ($method)",
      );
    } catch (e) {
      AppLogger.error("SignalR: HTTP Fallback Sinyali de basarisiz oldu!", e);
      // Hata firlatmak yerine gracefully durduruyoruz, boylece P2P cokuyorsa SFU'ya dusme isler.
    }
  }

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

  /// [ICE-BATCH] Birden fazla ICE candidate'i tek SignalR mesajında gönderir.
  /// Backend'de SendIceCandidatesBatch, her candidate'i peer'e iletiyor.
  Future<void> sendIceCandidatesBatch(
    String targetUserId,
    List<Map<String, dynamic>> candidates,
  ) async {
    if (!isConnected || candidates.isEmpty) return;
    try {
      final candidatesJson = jsonEncode(candidates);
      await _hubConnection!.invoke(
        'SendIceCandidatesBatch',
        args: [targetUserId, candidatesJson],
      );
      AppLogger.info(
        'SignalR: ICE batch gönderildi -> $targetUserId (${candidates.length} candidate)',
      );
    } catch (e) {
      AppLogger.error('SignalR: ICE batch gönderme hatası', e);
    }
  }

  // [NEW] Global ICE Cache for Zero-Latency 1v1 Calls
  List<Map<String, dynamic>>? _cachedIceServers;
  DateTime? _iceServersTimestamp;
  final Duration _iceCacheDuration = const Duration(minutes: 55);

  /// Backend'den TURN/STUN sunucu bilgilerini al
  /// GET /api/turn/ice-servers
  Future<List<Map<String, dynamic>>> fetchIceServers() async {
    if (_cachedIceServers != null && _iceServersTimestamp != null) {
      if (DateTime.now().difference(_iceServersTimestamp!) <
          _iceCacheDuration) {
        return _cachedIceServers!;
      }
    }

    try {
      final response = await _dio.get('api/turn/ice-servers');

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
      _cachedIceServers = iceServers;
      _iceServersTimestamp = DateTime.now();
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

  // DEPRECATED: Use rideTerminatedStream instead
  // void setOnRideTerminated(Function(String? rideId)? callback) {
  //   _onRideTerminated = callback;
  // }
}
