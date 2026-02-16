import 'dart:async';

import '../../../core/services/app_session.dart';
import '../../../core/services/audio_orchestrator_service.dart';
import '../../../core/services/livekit_api.dart';
import '../../../core/services/livekit_room_service.dart';
import '../../../core/services/permissions_service.dart';
import '../../../core/services/signalr_service.dart';
import '../../../core/services/webrtc_service.dart';
import '../domain/intercom_decision.dart';
import '../domain/intercom_engine.dart';
import '../domain/intercom_failure.dart';
import '../domain/intercom_models.dart';
import '../../voice_session/domain/enums/rtc_state.dart';

class IntercomEngineImpl implements IntercomEngine {
  final SignalRService signalRService;
  final WebRTCService webRTCService;
  final LiveKitApi liveKitApi;
  final LiveKitRoomService liveKitRoomService;
  final PermissionsService permissionsService;
  final AudioOrchestratorService audioOrchestratorService;
  final AppSession appSession;

  final StreamController<IntercomState> _stateController =
      StreamController<IntercomState>.broadcast();
  final StreamController<IntercomTelemetryEvent> _telemetryController =
      StreamController<IntercomTelemetryEvent>.broadcast();

  IntercomState _state = IntercomState.initial();
  IntercomPolicy _policy = const IntercomPolicy();
  IntercomStartOptions _options = const IntercomStartOptions();

  IntercomSessionContext? _context;
  bool _started = false;

  StreamSubscription? _lkConnectionSub;
  StreamSubscription? _lkSpeakersSub;
  StreamSubscription? _lkMicSub;

  StreamSubscription? _headlessRequestSub;
  StreamSubscription? _headlessAcceptedSub;
  StreamSubscription? _headlessEndedSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _webRtcIceSub;
  StreamSubscription? _webRtcConnectionSub;

  Timer? _p2pDebounceTimer;
  Timer? _sfuToP2pTimer;
  Timer? _reconnectTtlTimer;
  Timer? _reconnectRetryTimer;

  String? _p2pPeerUserId;
  bool _disconnectP2pWhenSfuConnected = false;
  bool _disconnectSfuWhenP2pConnected = false;

  int _reconnectAttempt = 0;
  DateTime? _switchStartedAt;
  IntercomTransport? _switchFrom;
  IntercomTransport? _switchTo;

  IntercomEngineImpl({
    required this.signalRService,
    required this.webRTCService,
    required this.liveKitApi,
    required this.liveKitRoomService,
    required this.permissionsService,
    required this.audioOrchestratorService,
    required this.appSession,
  });

  @override
  Stream<IntercomState> get state$ => _stateController.stream;

  @override
  Stream<IntercomTelemetryEvent> get telemetry$ => _telemetryController.stream;

  @override
  IntercomState get snapshot => _state;

  @override
  Future<void> start({
    IntercomPolicy policy = const IntercomPolicy(),
    IntercomStartOptions options = const IntercomStartOptions(),
  }) async {
    _policy = policy;
    _options = options;

    if (_started) {
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.start,
          name: IntercomTelemetryNames.engineStarted,
          data: const <String, Object?>{'idempotent': true},
        ),
      );
      return;
    }

    _started = true;
    _subscribeLiveKit();
    _subscribeSignalR();
    _subscribeWebRtc();

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.start,
        name: IntercomTelemetryNames.engineStarted,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _stopAllAudio();
    _cancelTimers();
    _cancelReconnectWorkflow();
    _context = null;
    _emitState(
      _state.copyWith(
        phase: IntercomPhase.idle,
        transport: IntercomTransport.none,
        rtcStatus: RtcConnectionStatus.disconnected,
        activeSpeakerIds: const <String>[],
        participants: const <IntercomParticipant>[],
      ),
    );

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.stop,
        name: IntercomTelemetryNames.engineStopped,
      ),
    );
  }

  @override
  Future<void> attachSession(IntercomSessionContext context) async {
    _context = context;

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.attachSession,
        name: IntercomTelemetryNames.sessionAttached,
        data: {
          IntercomTelemetryKeys.sessionId: context.sessionId,
          IntercomTelemetryKeys.roomName: context.roomName,
          IntercomTelemetryKeys.localUserId: context.localUserId,
          IntercomTelemetryKeys.hostUserId: context.hostUserId,
          IntercomTelemetryKeys.activeParticipantCount: context.activeCount,
          IntercomTelemetryKeys.activeParticipantUserIds:
              context.activeParticipantUserIds,
        },
      ),
    );

    _emitState(
      _state.copyWith(
        phase: IntercomPhase.evaluating,
        participants: context.participants ?? const <IntercomParticipant>[],
      ),
    );

    await _evaluateTransport(reason: IntercomDecisionReason.idle);
  }

  @override
  Future<void> detachSession({bool stopAudio = true}) async {
    _context = null;
    _cancelTimers();
    _cancelReconnectWorkflow();

    if (stopAudio) {
      await _stopAllAudio();
    }

    _emitState(
      _state.copyWith(
        phase: IntercomPhase.idle,
        transport: IntercomTransport.none,
        rtcStatus: RtcConnectionStatus.disconnected,
        activeSpeakerIds: const <String>[],
        participants: const <IntercomParticipant>[],
      ),
    );

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.detachSession,
        name: IntercomTelemetryNames.sessionDetached,
      ),
    );
  }

  @override
  Future<void> setMicEnabled(bool enabled) async {
    if (_state.transport == IntercomTransport.sfu) {
      await liveKitRoomService.setMicrophoneEnabled(enabled);
    } else if (_state.transport == IntercomTransport.p2p) {
      webRTCService.setMicrophoneEnabled(enabled);
    }

    _emitState(_state.copyWith(micEnabled: enabled));

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.setMicEnabled,
        name: IntercomTelemetryNames.micChanged,
        data: {IntercomTelemetryKeys.micEnabled: enabled},
      ),
    );
  }

  @override
  Future<void> toggleMic() async {
    await setMicEnabled(!_state.micEnabled);
  }

  @override
  Future<void> forceSwitchToP2p({String reason = 'manual'}) async {
    if (!_options.manualOverridesEnabled) {
      return;
    }
    await _switchToP2p(
      reason: IntercomDecisionReason.manual,
      manualReason: reason,
    );
  }

  @override
  Future<void> forceSwitchToSfu({String reason = 'manual'}) async {
    if (!_options.manualOverridesEnabled) {
      return;
    }
    await _switchToSfu(
      reason: IntercomDecisionReason.manual,
      manualReason: reason,
    );
  }

  @override
  Future<void> onLifecycleChanged(IntercomLifecycleState state) async {
    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.onLifecycleChanged,
        name: 'lifecycle.${state.name}',
      ),
    );

    if (state == IntercomLifecycleState.resumed) {
      _cancelReconnectWorkflow();
      if (_context != null) {
        await _evaluateTransport(reason: IntercomDecisionReason.recovery);
      }
      return;
    }

    if (state == IntercomLifecycleState.paused ||
        state == IntercomLifecycleState.detached ||
        state == IntercomLifecycleState.hidden) {
      await _stopAllAudio();
      _enterReconnecting(reason: 'lifecycle.${state.name}');
    }
  }

  @override
  Future<void> onConnectivityChanged({required bool online}) async {
    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.onConnectivityChanged,
        name: online ? 'connectivity.online' : 'connectivity.offline',
      ),
    );

    if (!online) {
      _enterReconnecting(reason: 'connectivity.offline');
      return;
    }

    _cancelReconnectWorkflow();
    if (_context != null) {
      await _evaluateTransport(reason: IntercomDecisionReason.recovery);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    _cancelTimers();
    _cancelReconnectWorkflow();

    await _lkConnectionSub?.cancel();
    await _lkSpeakersSub?.cancel();
    await _lkMicSub?.cancel();

    await _headlessRequestSub?.cancel();
    await _headlessAcceptedSub?.cancel();
    await _headlessEndedSub?.cancel();
    await _offerSub?.cancel();
    await _answerSub?.cancel();
    await _iceSub?.cancel();

    await _webRtcIceSub?.cancel();
    await _webRtcConnectionSub?.cancel();

    await _stateController.close();
    await _telemetryController.close();
  }

  void _subscribeLiveKit() {
    _lkConnectionSub?.cancel();
    _lkConnectionSub = liveKitRoomService.connectionStateStream.listen((state) {
      if (state.name == 'connected') {
        _cancelReconnectWorkflow();
        _emitState(
          _state.copyWith(
            rtcStatus: RtcConnectionStatus.sfuConnected,
            transport: IntercomTransport.sfu,
            phase: IntercomPhase.connected,
          ),
        );

        if (_disconnectP2pWhenSfuConnected) {
          _disconnectP2pWhenSfuConnected = false;
          _stopP2p();
        }

        _completeSwitchTelemetry(IntercomTransport.sfu);
        return;
      }

      if (state.name == 'reconnecting') {
        _enterReconnecting(reason: 'livekit.reconnecting');
        return;
      }

      if (state.name == 'disconnected') {
        _enterReconnecting(
          reason: 'livekit.disconnected',
          failure: const IntercomFailure(
            code: IntercomFailureCode.livekitConnectFailed,
            message: 'LiveKit disconnected',
          ),
        );
      }
    });

    _lkSpeakersSub?.cancel();
    _lkSpeakersSub = liveKitRoomService.activeSpeakersStream.listen((speakers) {
      final ids = speakers.map((s) => s.identity).toList();
      _emitState(_state.copyWith(activeSpeakerIds: ids));
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.attachSession,
          name: IntercomTelemetryNames.activeSpeakersChanged,
          data: {IntercomTelemetryKeys.activeSpeakerIds: ids},
        ),
      );
    });

    _lkMicSub?.cancel();
    _lkMicSub = liveKitRoomService.isMicEnabledStream.listen((enabled) {
      _emitState(_state.copyWith(micEnabled: enabled));
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.setMicEnabled,
          name: IntercomTelemetryNames.micChanged,
          data: {IntercomTelemetryKeys.micEnabled: enabled},
        ),
      );
    });
  }

  void _subscribeSignalR() {
    _headlessRequestSub?.cancel();
    _headlessRequestSub = signalRService.headlessCallRequestStream.listen((
      payload,
    ) {
      _onHeadlessRequest(payload.callerId);
    });

    _headlessAcceptedSub?.cancel();
    _headlessAcceptedSub = signalRService.headlessCallAcceptedStream.listen((
      payload,
    ) {
      _onHeadlessAccepted(payload.actorId);
    });

    _headlessEndedSub?.cancel();
    _headlessEndedSub = signalRService.headlessCallEndedStream.listen((
      payload,
    ) {
      _onHeadlessEnded(payload.actorId);
    });

    _offerSub?.cancel();
    _offerSub = signalRService.offerStream.listen((payload) {
      if (_state.transport != IntercomTransport.p2p) return;
      _onOffer(payload.userId, payload.sdp);
    });

    _answerSub?.cancel();
    _answerSub = signalRService.answerStream.listen((payload) {
      if (_state.transport != IntercomTransport.p2p) return;
      _onAnswer(payload.userId, payload.sdp);
    });

    _iceSub?.cancel();
    _iceSub = signalRService.iceCandidateStream.listen((payload) {
      if (_state.transport != IntercomTransport.p2p) return;
      _onIceCandidate(
        payload.fromUserId,
        payload.candidate,
        payload.sdpMid,
        payload.sdpMLineIndex,
      );
    });
  }

  void _subscribeWebRtc() {
    _webRtcIceSub?.cancel();
    _webRtcIceSub = webRTCService.onIceCandidate$.listen((candidate) async {
      final target = _p2pPeerUserId;
      if (target == null || target.isEmpty) return;
      await signalRService.sendIceCandidate(
        target,
        candidate.candidate ?? '',
        candidate.sdpMid,
        candidate.sdpMLineIndex,
      );
    });

    _webRtcConnectionSub?.cancel();
    _webRtcConnectionSub = webRTCService.connectionState$.listen((state) {
      if (_state.transport != IntercomTransport.p2p) return;

      if (state.name == 'RTCPeerConnectionStateConnected') {
        _cancelReconnectWorkflow();
        _emitState(
          _state.copyWith(
            rtcStatus: RtcConnectionStatus.p2pConnected,
            phase: IntercomPhase.connected,
          ),
        );

        if (_disconnectSfuWhenP2pConnected) {
          _disconnectSfuWhenP2pConnected = false;
          _disconnectLiveKit();
        }

        _completeSwitchTelemetry(IntercomTransport.p2p);
        return;
      }

      if (state.name == 'RTCPeerConnectionStateFailed' ||
          state.name == 'RTCPeerConnectionStateDisconnected') {
        _enterReconnecting(
          reason: 'webrtc.disconnected',
          failure: const IntercomFailure(
            code: IntercomFailureCode.webrtcIceFailed,
            message: 'WebRTC connection failed',
            recoverable: true,
          ),
        );
      }
    });
  }

  Future<void> _evaluateTransport({
    required IntercomDecisionReason reason,
  }) async {
    final context = _context;
    if (context == null) return;

    _cancelTimers();

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.attachSession,
        name: IntercomTelemetryNames.transportEvaluated,
        data: {
          IntercomTelemetryKeys.activeParticipantCount: context.activeCount,
        },
      ),
    );

    if (context.activeCount <= 1) {
      await _stopAllAudio();
      _emitDecision(
        IntercomDecision(
          target: IntercomTransport.none,
          reason: IntercomDecisionReason.idle,
          activeParticipantCount: context.activeCount,
          at: DateTime.now(),
        ),
      );
      _emitState(
        _state.copyWith(
          phase: IntercomPhase.idle,
          transport: IntercomTransport.none,
          rtcStatus: RtcConnectionStatus.disconnected,
        ),
      );
      return;
    }

    if (context.activeCount >= 3) {
      _disconnectSfuWhenP2pConnected = false;
      await _switchToSfu(
        reason: IntercomDecisionReason.threeOrMoreParticipantsSfu,
      );
      return;
    }

    if (_state.transport == IntercomTransport.sfu) {
      _sfuToP2pTimer = Timer(_policy.sfuToP2pDelay, () {
        _switchToP2p(
          reason: IntercomDecisionReason.twoParticipantsP2p,
          delayApplied: _policy.sfuToP2pDelay,
        );
      });
      _emitDecision(
        IntercomDecision(
          target: IntercomTransport.p2p,
          reason: IntercomDecisionReason.awaitingSecondPartyStability,
          activeParticipantCount: context.activeCount,
          delayApplied: _policy.sfuToP2pDelay,
          at: DateTime.now(),
        ),
      );
      return;
    }

    _p2pDebounceTimer = Timer(_policy.p2pDecisionDelay, () {
      _switchToP2p(
        reason: IntercomDecisionReason.twoParticipantsP2p,
        delayApplied: _policy.p2pDecisionDelay,
      );
    });

    _emitState(
      _state.copyWith(
        phase: IntercomPhase.evaluating,
        transport: IntercomTransport.none,
        rtcStatus: RtcConnectionStatus.disconnected,
      ),
    );

    _emitDecision(
      IntercomDecision(
        target: IntercomTransport.p2p,
        reason: IntercomDecisionReason.awaitingSecondPartyStability,
        activeParticipantCount: context.activeCount,
        delayApplied: _policy.p2pDecisionDelay,
        at: DateTime.now(),
      ),
    );
  }

  Future<void> _switchToSfu({
    required IntercomDecisionReason reason,
    Duration? delayApplied,
    String? manualReason,
  }) async {
    final context = _context;
    if (context == null) return;

    // Safety check: if stopped or disposed
    if (!_started) return;

    _emitDecision(
      IntercomDecision(
        target: IntercomTransport.sfu,
        reason: reason,
        activeParticipantCount: context.activeCount,
        delayApplied: delayApplied,
        at: DateTime.now(),
      ),
    );

    if (_state.transport == IntercomTransport.sfu &&
        _state.rtcStatus == RtcConnectionStatus.sfuConnected) {
      return;
    }

    final previousTransport = _state.transport;
    _beginSwitchTelemetry(
      to: IntercomTransport.sfu,
      manualReason: manualReason,
    );

    _disconnectP2pWhenSfuConnected = previousTransport == IntercomTransport.p2p;

    final permissionsOk = await permissionsService
        .ensureVoiceSessionPermissions(requestLocation: false);
    if (!permissionsOk) {
      // Robustness: If we are already in P2P, don't break the call.
      // Just log warning and stay in P2P.
      if (previousTransport == IntercomTransport.p2p) {
        _emitTelemetry(
          IntercomTelemetryEvent.now(
            command: IntercomCommand.forceSwitchToSfu,
            name: 'switch_aborted_permissions_denied',
            data: {'reason': 'permission_denied_keeping_p2p'},
          ),
        );
        return;
      }

      _emitFailure(
        const IntercomFailure(
          code: IntercomFailureCode.permissionsDenied,
          message: 'Voice permissions denied',
          recoverable: false,
        ),
      );
      return;
    }

    _emitState(
      _state.copyWith(
        transport: IntercomTransport.sfu,
        phase: IntercomPhase.connecting,
        rtcStatus: RtcConnectionStatus.sfuConnecting,
      ),
    );

    try {
      final tokenData = await liveKitApi.getToken(
        roomName: context.roomName,
        displayName: _contextDisplayName(context),
      );
      final token = tokenData['token'] ?? '';
      final url = tokenData['url'] ?? '';
      if (token.isEmpty || url.isEmpty) {
        throw Exception('LiveKit token empty');
      }

      await liveKitRoomService.connect(url, token);
      await audioOrchestratorService.manageAudioFocus(true);

      if (_disconnectP2pWhenSfuConnected) {
        await _stopP2p();
        _disconnectP2pWhenSfuConnected = false;
      }

      _completeSwitchTelemetry(IntercomTransport.sfu);
    } catch (e, stack) {
      _emitSwitchFailureTelemetry(IntercomTransport.sfu);
      // If we failed to switch to SFU, we try to recover or stay in P2P if possible?
      // For now, standard error handling:
      _enterReconnecting(
        reason: 'switch_to_sfu_failed',
        failure: IntercomFailure(
          code: IntercomFailureCode.livekitConnectFailed,
          message: 'LiveKit connect failed',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<void> _switchToP2p({
    required IntercomDecisionReason reason,
    Duration? delayApplied,
    String? manualReason,
  }) async {
    final context = _context;
    if (context == null) return;

    _emitDecision(
      IntercomDecision(
        target: IntercomTransport.p2p,
        reason: reason,
        activeParticipantCount: context.activeCount,
        delayApplied: delayApplied,
        at: DateTime.now(),
      ),
    );

    if (_state.transport == IntercomTransport.p2p &&
        _state.rtcStatus == RtcConnectionStatus.p2pConnected) {
      return;
    }

    final previousTransport = _state.transport;
    _beginSwitchTelemetry(
      to: IntercomTransport.p2p,
      manualReason: manualReason,
    );

    _disconnectSfuWhenP2pConnected = previousTransport == IntercomTransport.sfu;

    _emitState(
      _state.copyWith(
        transport: IntercomTransport.p2p,
        phase: IntercomPhase.connecting,
        rtcStatus: RtcConnectionStatus.p2pConnecting,
      ),
    );

    await audioOrchestratorService.manageAudioFocus(true);

    final localUserId = context.localUserId;
    if (localUserId == context.hostUserId) {
      final peerId = _resolveP2pPeerId(context);
      if (peerId == null) return;
      _p2pPeerUserId = peerId;
      await signalRService.sendHeadlessCallRequest(peerId);
    }
  }

  Future<void> _onHeadlessRequest(String callerId) async {
    _p2pPeerUserId = callerId;
    await signalRService.acceptHeadlessCall(callerId);
  }

  Future<void> _onHeadlessAccepted(String userId) async {
    if (_state.transport != IntercomTransport.p2p) return;

    _p2pPeerUserId = userId;
    try {
      await _prepareWebRtcForOffer();
      final offer = await webRTCService.createOffer();
      final sdp = offer.sdp;
      if (sdp == null || sdp.isEmpty) {
        throw StateError('WebRTC offer empty');
      }
      await signalRService.sendOffer(userId, sdp);
    } catch (e, stack) {
      _enterReconnecting(
        reason: 'webrtc.offer_failed',
        failure: IntercomFailure(
          code: IntercomFailureCode.webrtcOfferFailed,
          message: 'WebRTC offer failed',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<void> _onHeadlessEnded(String userId) async {
    await _stopP2p();
    _emitState(
      _state.copyWith(
        rtcStatus: RtcConnectionStatus.disconnected,
        phase: IntercomPhase.idle,
      ),
    );
    if (_context != null) {
      await _evaluateTransport(reason: IntercomDecisionReason.recovery);
    }
  }

  Future<void> _onOffer(String userId, String sdp) async {
    _p2pPeerUserId = userId;
    final answerSdp = await webRTCService.handleOffer(userId, sdp);
    if (answerSdp != null) {
      await signalRService.sendAnswer(userId, answerSdp);
    } else {
      _enterReconnecting(
        reason: 'webrtc.answer_failed',
        failure: const IntercomFailure(
          code: IntercomFailureCode.webrtcAnswerFailed,
          message: 'WebRTC answer failed',
        ),
      );
    }
  }

  Future<void> _onAnswer(String userId, String sdp) async {
    await webRTCService.handleAnswer(userId, sdp);
  }

  Future<void> _onIceCandidate(
    String userId,
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    await webRTCService.addIceCandidate(candidate, sdpMid, sdpMLineIndex);
  }

  Future<void> _prepareWebRtcForOffer() async {
    final ice = await liveKitApi.getIceServers();
    final servers =
        (ice['iceServers'] as List?)?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];

    await webRTCService.stopAll();
    await webRTCService.initialize(servers);
    await webRTCService.startLocalStream();
  }

  Future<void> _stopAllAudio() async {
    await _stopP2p();
    await _disconnectLiveKit();
    await audioOrchestratorService.manageAudioFocus(false);
  }

  Future<void> _stopP2p() async {
    _p2pPeerUserId = null;
    await webRTCService.stopAll();
  }

  Future<void> _disconnectLiveKit() async {
    await liveKitRoomService.disconnect();
  }

  String? _resolveP2pPeerId(IntercomSessionContext context) {
    for (final id in context.activeParticipantUserIds) {
      if (id != context.localUserId) {
        return id.toString();
      }
    }
    return null;
  }

  String? _contextDisplayName(IntercomSessionContext context) {
    final local = context.participants?.firstWhere(
      (p) => p.userId == context.localUserId,
      orElse: () => const IntercomParticipant(userId: -1, isLocal: true),
    );
    if (local == null) return null;
    return local.displayName;
  }

  void _emitDecision(IntercomDecision decision) {
    _emitState(_state.copyWith(lastDecision: decision));
    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.attachSession,
        name: IntercomTelemetryNames.transportDecision,
        data: {
          IntercomTelemetryKeys.toTransport: decision.target.name,
          IntercomTelemetryKeys.decisionReason: decision.reason.name,
          IntercomTelemetryKeys.activeParticipantCount:
              decision.activeParticipantCount,
          if (decision.delayApplied != null)
            IntercomTelemetryKeys.delayMs:
                decision.delayApplied!.inMilliseconds,
        },
      ),
    );
  }

  void _emitFailure(IntercomFailure failure) {
    _emitState(
      _state.copyWith(
        phase: IntercomPhase.failed,
        rtcStatus: RtcConnectionStatus.failed,
        lastFailure: failure,
        lastError: failure,
      ),
    );

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        level: IntercomTelemetryLevel.error,
        command: IntercomCommand.stopAll,
        name: IntercomTelemetryNames.failure,
        data: {
          IntercomTelemetryKeys.failureCode: failure.code.name,
          IntercomTelemetryKeys.failureMessage: failure.message,
          IntercomTelemetryKeys.recoverable: failure.recoverable,
        },
      ),
    );
  }

  void _enterReconnecting({required String reason, IntercomFailure? failure}) {
    _emitState(
      _state.copyWith(
        phase: IntercomPhase.reconnecting,
        rtcStatus: RtcConnectionStatus.reconnecting,
        lastFailure: failure ?? _state.lastFailure,
        lastError: failure ?? _state.lastError,
      ),
    );

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        level: IntercomTelemetryLevel.warning,
        command: IntercomCommand.onConnectivityChanged,
        name: IntercomTelemetryNames.reconnectStarted,
        data: {
          'reason': reason,
          if (failure != null)
            IntercomTelemetryKeys.failureCode: failure.code.name,
        },
      ),
    );

    _startReconnectTtl();
    _startReconnectRetry();
  }

  void _startReconnectRetry() {
    _reconnectRetryTimer?.cancel();
    _reconnectAttempt = 0;
    _reconnectRetryTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _retryReconnect(),
    );
  }

  Future<void> _retryReconnect() async {
    final context = _context;
    if (context == null) return;

    if (_state.rtcStatus == RtcConnectionStatus.p2pConnected ||
        _state.rtcStatus == RtcConnectionStatus.sfuConnected) {
      _cancelReconnectWorkflow();
      return;
    }

    _reconnectAttempt += 1;
    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.onConnectivityChanged,
        name: IntercomTelemetryNames.reconnectAttempt,
        data: {
          IntercomTelemetryKeys.retryAttempt: _reconnectAttempt,
          IntercomTelemetryKeys.activeParticipantCount: context.activeCount,
        },
      ),
    );

    await _evaluateTransport(reason: IntercomDecisionReason.recovery);

    if (_state.rtcStatus == RtcConnectionStatus.p2pConnected ||
        _state.rtcStatus == RtcConnectionStatus.sfuConnected) {
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.onConnectivityChanged,
          name: IntercomTelemetryNames.reconnectRecovered,
          data: {IntercomTelemetryKeys.retryAttempt: _reconnectAttempt},
        ),
      );
      _cancelReconnectWorkflow();
    }
  }

  void _cancelReconnectWorkflow() {
    _cancelReconnectTtl();
    _reconnectRetryTimer?.cancel();
    _reconnectRetryTimer = null;
    _reconnectAttempt = 0;
  }

  void _beginSwitchTelemetry({
    required IntercomTransport to,
    String? manualReason,
  }) {
    _switchStartedAt = DateTime.now();
    _switchFrom = _state.transport;
    _switchTo = to;

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: to == IntercomTransport.sfu
            ? IntercomCommand.forceSwitchToSfu
            : IntercomCommand.forceSwitchToP2p,
        name: IntercomTelemetryNames.transportSwitchStarted,
        data: {
          IntercomTelemetryKeys.fromTransport: _switchFrom?.name,
          IntercomTelemetryKeys.toTransport: to.name,
          if (manualReason != null) 'reason': manualReason,
        },
      ),
    );
  }

  void _completeSwitchTelemetry(IntercomTransport connectedTransport) {
    if (_switchTo != connectedTransport) return;
    final startedAt = _switchStartedAt;
    final durationMs = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inMilliseconds;

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: connectedTransport == IntercomTransport.sfu
            ? IntercomCommand.forceSwitchToSfu
            : IntercomCommand.forceSwitchToP2p,
        name: IntercomTelemetryNames.transportSwitchSucceeded,
        data: {
          IntercomTelemetryKeys.fromTransport: _switchFrom?.name,
          IntercomTelemetryKeys.toTransport: connectedTransport.name,
          if (durationMs != null) IntercomTelemetryKeys.durationMs: durationMs,
        },
      ),
    );

    _switchStartedAt = null;
    _switchFrom = null;
    _switchTo = null;
  }

  void _emitSwitchFailureTelemetry(IntercomTransport target) {
    final startedAt = _switchStartedAt;
    final durationMs = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inMilliseconds;

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        level: IntercomTelemetryLevel.error,
        command: target == IntercomTransport.sfu
            ? IntercomCommand.forceSwitchToSfu
            : IntercomCommand.forceSwitchToP2p,
        name: IntercomTelemetryNames.transportSwitchFailed,
        data: {
          IntercomTelemetryKeys.fromTransport: _switchFrom?.name,
          IntercomTelemetryKeys.toTransport: target.name,
          if (durationMs != null) IntercomTelemetryKeys.durationMs: durationMs,
        },
      ),
    );

    _switchStartedAt = null;
    _switchFrom = null;
    _switchTo = null;
  }

  void _emitState(IntercomState next) {
    _state = next.copyWith(updatedAt: DateTime.now());
    _stateController.add(_state);
  }

  void _emitTelemetry(IntercomTelemetryEvent event) {
    if (!_options.telemetryEnabled) return;
    _telemetryController.add(event);
  }

  void _cancelTimers() {
    _p2pDebounceTimer?.cancel();
    _sfuToP2pTimer?.cancel();
    _reconnectRetryTimer?.cancel();

    _p2pDebounceTimer = null;
    _sfuToP2pTimer = null;
    _reconnectRetryTimer = null;
  }

  void _startReconnectTtl() {
    _cancelReconnectTtl();
    _reconnectTtlTimer = Timer(_policy.reconnectTtl, () {
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          level: IntercomTelemetryLevel.error,
          command: IntercomCommand.onConnectivityChanged,
          name: IntercomTelemetryNames.reconnectExpired,
        ),
      );
      _emitFailure(
        const IntercomFailure(
          code: IntercomFailureCode.reconnectTtlExceeded,
          message: 'Reconnect TTL exceeded',
          recoverable: false,
        ),
      );
    });
  }

  void _cancelReconnectTtl() {
    _reconnectTtlTimer?.cancel();
    _reconnectTtlTimer = null;
  }
}
