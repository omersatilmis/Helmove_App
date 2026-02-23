import 'dart:async';
import 'dart:io';
import 'package:livekit_client/livekit_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/adaptive_bitrate_controller.dart';
import '../../../core/services/app_session.dart';
import '../../../core/services/audio_orchestrator_service.dart';
import '../../../core/services/livekit_api.dart';
import '../../../core/services/livekit_room_service.dart';
import '../../../core/services/permissions_service.dart';
import '../../../core/services/signalr_service.dart';
import '../../../core/services/webrtc_service.dart';
import '../../../core/services/app_background_service.dart';
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
  StreamSubscription? _lkQualitySub;

  StreamSubscription? _headlessRequestSub;
  StreamSubscription? _headlessAcceptedSub;
  StreamSubscription? _headlessEndedSub;
  StreamSubscription? _headlessFailedSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceSub;
  StreamSubscription? _webRtcIceSub;
  StreamSubscription? _webRtcConnectionSub;
  StreamSubscription? _adaptiveBitrateSub;

  // Adaptive Bitrate Controller
  final AdaptiveBitrateController _bitrateController =
      AdaptiveBitrateController();

  Timer? _p2pDebounceTimer;
  Timer? _sfuToP2pTimer;
  Timer? _reconnectTtlTimer;
  Timer? _reconnectRetryTimer;
  Timer? _p2pToSfuHysteresisTimer; // [NEW] Hysteresis
  Timer? _transportOverlapTimer; // [NEW] Overlap Timer for Seamless Switching
  Timer? _headlessCallTimeoutTimer; // Peer offline timeout

  // [NEW] Token Caching
  String? _cachedLiveKitToken;
  String? _cachedLiveKitUrl;
  List<Map<String, dynamic>>? _cachedIceServers;
  DateTime? _tokenTimestamp;
  static const Duration _tokenTtl = Duration(minutes: 30);

  String? _p2pPeerUserId;
  bool _disconnectP2pWhenSfuConnected = false;
  bool _disconnectSfuWhenP2pConnected = false;

  int _reconnectAttempt = 0;
  DateTime? _switchStartedAt;
  IntercomTransport? _switchFrom;
  IntercomTransport? _switchTo;

  // Smart Reconnect — network type tracking
  String? _lastNetworkType;
  Timer? _iceRestartFallbackTimer;

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

    // [NEW] Start Background Service for Android
    if (Platform.isAndroid) {
      await AppBackgroundService.start();
    }

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
    _cancelPendingSwitches(); // Ensure explicit clear
    _cancelReconnectWorkflow();
    _context = null;

    // [NEW] Stop Background Service for Android
    if (Platform.isAndroid) {
      await AppBackgroundService.stop();
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
        command: IntercomCommand.stop,
        name: IntercomTelemetryNames.engineStopped,
      ),
    );
  }

  @override
  Future<void> attachSession(IntercomSessionContext context) async {
    // Optimization: Skip if context hasn't changed (same sessionId and participant count)
    if (_context?.sessionId == context.sessionId &&
        _context?.activeCount == context.activeCount &&
        _context?.hostUserId == context.hostUserId &&
        _state.phase == IntercomPhase.connected) {
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.attachSession,
          name: 'attach_skipped_already_connected',
        ),
      );
      return;
    }

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
      // [NEW] Stop Background Service for Android only if we are fully stopping
      if (Platform.isAndroid) {
        await AppBackgroundService.stop();
      }
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

    // ── WhatsApp / Discord Davranışı ──────────────────────────────
    // paused/hidden: Kullanıcı kısa süreli uygulama değiştirdi veya ekran
    //   kilitledi → ses bağlantısını KORUMA. Kesersek her seferinde
    //   reconnect döngüsü başlar ve karşı taraf da arka plandaysa
    //   headless call yanıtsız kalır → sonsuz döngü.
    // detached: Uygulama tamamen kapatılıyor → ses temizleyip reconnect
    //   hazırlığına geç (foreground service varsa bile bağlantı riskli).
    if (state == IntercomLifecycleState.detached) {
      await _stopAllAudio();
      _enterReconnecting(reason: 'lifecycle.${state.name}');
    }
  }

  @override
  Future<void> onAudioSettingsChanged() async {
    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.onAudioSettingsChanged,
        name: 'audio_settings_refresh',
      ),
    );

    try {
      final sharedPrefs = await SharedPreferences.getInstance();

      // ── 1) Bitrate Ceiling ─────────────────────────────────
      // Kullanıcının ayarlardan seçtiği kaliteyi oku → AdaptiveBitrateController'a ilet.
      // Controller tavanı günceller ve sinyal iyiyse yeni bitrate'i
      // bitrate$ stream üzerinden hem P2P'ye hem SFU'ya otomatik iletir.
      final qualityKey = sharedPrefs.getString('audio_quality_key');
      _bitrateController.updateCeilingFromKey(qualityKey);

      // ── 2) Noise Suppression ───────────────────────────────
      final noiseSuppression =
          sharedPrefs.getBool('audio_noise_suppression') ?? true;

      if (_state.transport == IntercomTransport.sfu) {
        await liveKitRoomService.updateAudioSettings(
          noiseSuppression: noiseSuppression,
        );
      } else if (_state.transport == IntercomTransport.p2p) {
        await webRTCService.updateAudioSettings(
          noiseSuppression: noiseSuppression,
        );
      }

      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.onAudioSettingsChanged,
          name: 'audio_settings_applied',
          data: {
            'ceiling': _bitrateController.ceilingBitrate,
            'effective': _bitrateController.effectiveBitrate,
            'noiseSuppression': noiseSuppression,
          },
        ),
      );
    } catch (e) {
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.onAudioSettingsChanged,
          name: 'audio_settings_refresh_failed',
          data: {'error': e.toString()},
        ),
      );
    }
  }

  @override
  Future<void> onConnectivityChanged({
    required bool online,
    String? networkType,
  }) async {
    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.onConnectivityChanged,
        name: online ? 'connectivity.online' : 'connectivity.offline',
        data: {'networkType': networkType ?? 'unknown'},
      ),
    );

    if (!online) {
      _lastNetworkType = null;
      _enterReconnecting(reason: 'connectivity.offline');
      return;
    }

    // Network switch detection (WiFi → Mobile veya tersi)
    final isNetworkSwitch =
        _lastNetworkType != null &&
        networkType != null &&
        _lastNetworkType != networkType;
    _lastNetworkType = networkType;

    if (isNetworkSwitch && _context != null) {
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.onConnectivityChanged,
          name: 'connectivity.network_switch',
          data: {'from': _lastNetworkType, 'to': networkType},
        ),
      );

      // P2P aktifse proaktif ICE Restart
      if (_state.transport == IntercomTransport.p2p) {
        final offer = await webRTCService.restartIce();
        if (offer != null) {
          // Yeni ICE offer'i karşı tarafa gönder
          final peerId = _p2pPeerUserId;
          if (peerId != null) {
            signalRService.sendOffer(peerId, offer.sdp!);
          }

          // 5 saniye içinde bağlanmazsa full reconnect'e geç
          _iceRestartFallbackTimer?.cancel();
          _iceRestartFallbackTimer = Timer(const Duration(seconds: 5), () {
            if (_state.rtcStatus != RtcConnectionStatus.p2pConnected) {
              _emitTelemetry(
                IntercomTelemetryEvent.now(
                  command: IntercomCommand.onConnectivityChanged,
                  name: 'connectivity.ice_restart_fallback',
                ),
              );
              _evaluateTransport(reason: IntercomDecisionReason.recovery);
            }
          });
          return;
        }
      }
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
    await _headlessFailedSub?.cancel();
    _headlessCallTimeoutTimer?.cancel();
    await _offerSub?.cancel();
    await _answerSub?.cancel();
    await _iceSub?.cancel();

    await _webRtcIceSub?.cancel();
    await _webRtcConnectionSub?.cancel();
    await _adaptiveBitrateSub?.cancel();

    _bitrateController.dispose();
    _iceRestartFallbackTimer?.cancel();

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
          // [NEW] Seamless Switch: Delay P2P disconnect by 1 second
          _transportOverlapTimer?.cancel();
          // [NEW] Echo Control: Immediately mute P2P audio to prevent double audio
          webRTCService.setRemoteAudioEnabled(false);
          _transportOverlapTimer = Timer(
            const Duration(milliseconds: 1000),
            () {
              _stopP2p();
            },
          );
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

    _lkQualitySub?.cancel();
    _lkQualitySub = liveKitRoomService.qualityStream.listen((qualities) {
      final updatedParticipants = _state.participants.map((p) {
        final identity = p.userId.toString();
        if (qualities.containsKey(identity)) {
          return p.copyWith(
            connectionQuality: _mapLiveKitQuality(qualities[identity]!),
          );
        }
        return p;
      }).toList();

      _emitState(_state.copyWith(participants: updatedParticipants));

      // Feed local participant quality to adaptive bitrate controller
      final localId = appSession.currentUserId?.toString();
      if (localId != null && qualities.containsKey(localId)) {
        _bitrateController.onQualityChanged(
          _mapLiveKitQuality(qualities[localId]!),
        );
      }
    });

    // Subscribe to adaptive bitrate changes
    _adaptiveBitrateSub?.cancel();
    _adaptiveBitrateSub = _bitrateController.bitrate$.listen((bps) {
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.onAudioSettingsChanged,
          name: 'adaptive_bitrate.changed',
          data: {
            'effectiveBitrate': bps,
            'ceiling': _bitrateController.ceilingBitrate,
          },
        ),
      );

      // P2P aktifse WebRTC bitrate'ini güncelle
      if (_state.transport == IntercomTransport.p2p) {
        webRTCService.setBitrate(bps);
      }

      // SFU aktifse LiveKit bitrate'ini güncelle
      if (_state.transport == IntercomTransport.sfu) {
        liveKitRoomService.updateBitrate(bps);
      }
    });
  }

  IntercomConnectionQuality _mapLiveKitQuality(ConnectionQuality lkQuality) {
    switch (lkQuality) {
      case ConnectionQuality.excellent:
        return IntercomConnectionQuality.excellent;
      case ConnectionQuality.good:
        return IntercomConnectionQuality.good;
      case ConnectionQuality.poor:
        return IntercomConnectionQuality.poor;
      case ConnectionQuality.lost:
        return IntercomConnectionQuality.lost;
      default:
        return IntercomConnectionQuality.unknown;
    }
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

    _headlessFailedSub?.cancel();
    _headlessFailedSub = signalRService.headlessCallFailedStream.listen((
      targetUserId,
    ) {
      _onHeadlessCallFailed(targetUserId);
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
        _headlessCallTimeoutTimer
            ?.cancel(); // [NEW] Safety: Ensure timeout is cancelled
        _emitState(
          _state.copyWith(
            rtcStatus: RtcConnectionStatus.p2pConnected,
            phase: IntercomPhase.connected,
          ),
        );

        if (_disconnectSfuWhenP2pConnected) {
          _disconnectSfuWhenP2pConnected = false;
          // [NEW] Seamless Switch: Delay SFU disconnect by 1 second
          _transportOverlapTimer?.cancel();

          // [NEW] Echo Control: Immediately mute SFU audio to prevent double audio
          liveKitRoomService.setIncomingAudioEnabled(false);

          _transportOverlapTimer = Timer(
            const Duration(milliseconds: 1000),
            () {
              _disconnectLiveKit();
            },
          );
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

    // [NEW] Use centralized cancel
    _cancelPendingSwitches();

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

    // [NEW] Pre-fetch token when 2 participants (Anticipation)
    if (context.activeCount == 2) {
      _prefetchLiveKitToken();
    }

    if (context.activeCount >= 3) {
      _disconnectSfuWhenP2pConnected = false;

      // [NEW] Hysteresis: Wait 2 seconds before switching to SFU to prevent flapping
      _p2pToSfuHysteresisTimer = Timer(const Duration(seconds: 2), () {
        _switchToSfu(reason: IntercomDecisionReason.threeOrMoreParticipantsSfu);
      });
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
        clearError: true, // [NEW] Clear previous failures
      ),
    );

    try {
      String token = '';
      String url = '';

      final now = DateTime.now();
      final useCache = _tokenTimestamp != null && now.difference(_tokenTimestamp!) < _tokenTtl;

      // [FAST-SFU] Eger token ve url onceden prefetch edildiyse, LiveKit baglantisi 0 ms bekler.
      if (useCache && _cachedLiveKitToken != null && _cachedLiveKitUrl != null) {
        token = _cachedLiveKitToken!;
        url = _cachedLiveKitUrl!;
      } else {
        final tokenData = await liveKitApi.getToken(
          roomName: context.roomName,
          identity: context.localUserId.toString(),
          displayName: _contextDisplayName(context),
        );
        token = tokenData['token'] ?? '';
        url = tokenData['url'] ?? '';

        if (token.isNotEmpty && url.isNotEmpty) {
          _cachedLiveKitToken = token;
          _cachedLiveKitUrl = url;
          _tokenTimestamp = now;
        }
      }

      if (token.isEmpty || url.isEmpty) {
        throw Exception('LiveKit token empty');
      }

      await liveKitRoomService.connect(
        url,
        token,
        maxBitrate: _bitrateController.ceilingBitrate,
      );
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
        clearError: true, // [NEW] Clear previous failures
      ),
    );

    await audioOrchestratorService.manageAudioFocus(true);

    // [FAST-ICE & EARLY MEDIA / PRE-WARMING]
    // Hem Host hem Invitee icin WebRTC'yi simdiden hazirla (Mikrofon izni vs. 1-2 saniye surer).
    // Bu sayede Offer ve Answer asamasinda hardware spin-up suresi beklenmez, baglanti ANINDA kurulur.
    try {
      await _prepareWebRtcForOffer();
    } catch (e, stack) {
      _enterReconnecting(
        reason: 'webrtc.prepare_failed',
        failure: IntercomFailure(
          code: IntercomFailureCode.webrtcOfferFailed,
          message: 'Failed to access mic or init WebRTC',
          cause: e,
          stackTrace: stack,
        ),
      );
      return;
    }

    final localUserId = context.localUserId;
    if (localUserId == context.hostUserId) {
      final peerId = _resolveP2pPeerId(context);
      if (peerId == null) return;
      _p2pPeerUserId = peerId;
      await signalRService.sendHeadlessCallRequest(peerId);

      // ── Headless Call Timeout ──────────────────────────────────
      // Peer 10s içinde kabul etmezse (offline/arka planda olabilir)
      // reconnecting'e düş — süresiz bekleme yok.
      _headlessCallTimeoutTimer?.cancel();
      _headlessCallTimeoutTimer = Timer(const Duration(seconds: 10), () {
        if (_state.rtcStatus == RtcConnectionStatus.p2pConnecting) {
          _enterReconnecting(
            reason: 'headless.timeout',
            failure: const IntercomFailure(
              code: IntercomFailureCode.webrtcOfferFailed,
              message: 'Peer did not respond to headless call within 10s',
              recoverable: true,
            ),
          );
        }
      });
    } else {
      // ── Symmetric Timeout (Invitee Side) ─────────────────────────
      // [NEW] Kurucu (Host) değilsek, Host'tan Offer gelmesini bekliyoruz.
      // Eğer Host 15 saniye içinde Offer yollamazsa (ağ koptuysa vs.) sonsuza
      // kadar "Bağlanıyor..." kalmamak için zaman aşımı başlatıyoruz.
      _headlessCallTimeoutTimer?.cancel();
      _headlessCallTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (_state.rtcStatus == RtcConnectionStatus.p2pConnecting) {
          _enterReconnecting(
            reason: 'invitee.offer_timeout',
            failure: const IntercomFailure(
              code: IntercomFailureCode.webrtcOfferFailed,
              message: 'Host did not send WebRTC offer within 15s',
              recoverable: true,
            ),
          );
        }
      });
    }
  }

  Future<void> _onHeadlessRequest(String callerId) async {
    // [NEW] Handshake Validation: Sadece P2P modundaysak ve bağlanıyorsak kabul et
    if (_state.transport != IntercomTransport.p2p) return;

    _p2pPeerUserId = callerId;
    await signalRService.acceptHeadlessCall(callerId);

    // [NEW] Sinyali kabul ettik, şimdi Host'tan Offer gelmesini bekliyoruz.
    // Timeout sayacını sıfırdan 15 saniyeye kuruyoruz ki Offer yolda kaybolursa
    // sınırsız bekleme (6 dakika kilitlenme) olmasın.
    _headlessCallTimeoutTimer?.cancel();
    _headlessCallTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (_state.rtcStatus == RtcConnectionStatus.p2pConnecting) {
        _enterReconnecting(
          reason: 'invitee.offer_timeout_after_accept',
          failure: const IntercomFailure(
            code: IntercomFailureCode.webrtcOfferFailed,
            message: 'Host did not send offer after accept inside 15s',
            recoverable: true,
          ),
        );
      }
    });
  }

  /// Peer offline olduğunda backend'den gelen callback.
  void _onHeadlessCallFailed(String targetUserId) {
    _headlessCallTimeoutTimer?.cancel();
    if (_state.rtcStatus != RtcConnectionStatus.p2pConnecting) return;

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        level: IntercomTelemetryLevel.warning,
        command: IntercomCommand.attachSession,
        name: 'headless_call_failed',
        data: {'targetUserId': targetUserId, 'reason': 'peer_offline'},
      ),
    );

    _enterReconnecting(
      reason: 'headless.peer_offline',
      failure: const IntercomFailure(
        code: IntercomFailureCode.peerUnavailable,
        message: 'Peer is offline/unreachable',
        recoverable: true,
      ),
    );
  }

  Future<void> _onHeadlessAccepted(String userId) async {
    _headlessCallTimeoutTimer?.cancel(); // Timeout iptal — peer yanıt verdi
    if (_state.transport != IntercomTransport.p2p) return;

    _p2pPeerUserId = userId;
    try {
      // KOD SILINDI: await _prepareWebRtcForOffer(); -> Cünkü _switchToP2p anında donanım (mikrofon) ısındı!
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
    // [NEW] Host Offer yolladı. Simetrik timeout'u iptal edebiliriz, süreç başarıyla ilerliyor.
    _headlessCallTimeoutTimer?.cancel();
    _p2pPeerUserId = userId;
    try {
      if (_state.transport != IntercomTransport.p2p) return;
      
      // KOD DEGISTIRILDI: handleOffer icindeki initialize, stopAll vb. hardware-spin kaldirildi! 
      // Zaten _switchToP2p isinildi. Yalnizca saf WebSocket String set etmesi yapiliyor (Sifir Gecikme).
      await webRTCService.setRemoteDescription('offer', sdp);
      final answer = await webRTCService.createAnswer();
      final answerSdp = answer.sdp;
      
      if (answerSdp != null) {
        await signalRService.sendAnswer(userId, answerSdp);
      } else {
        throw StateError('Answer SDP is null');
      }
    } catch (e, stack) {
      _enterReconnecting(
        reason: 'webrtc.answer_failed',
        failure: IntercomFailure(
          code: IntercomFailureCode.webrtcAnswerFailed,
          message: 'Failed to handle offer or send answer',
          cause: e,
          stackTrace: stack,
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
    // [NEW] Use Prefetched ICE servers if available (Zero Api wait)
    List<Map<String, dynamic>> servers = _cachedIceServers ?? const <Map<String, dynamic>>[];
    if (servers.isEmpty) {
      final ice = await liveKitApi.getIceServers();
      servers = (ice['iceServers'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      _cachedIceServers = servers;
    }

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
    _reconnectAttempt =
        0; // [FIX] Reset retry counter for new reconnection phase

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
    // _reconnectAttempt = 0; // Don't reset here, let it accumulate or reset in _enterReconnecting
    _reconnectRetryTimer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _retryReconnect(),
    );
  }

  Future<void> _retryReconnect() async {
    final context = _context;
    if (context == null) return;

    // [FIX] Max Retries to prevent infinite loop
    if (_reconnectAttempt >= 5) {
      // 5 * 6s = 30s timeout
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          level: IntercomTelemetryLevel.error,
          command: IntercomCommand.onConnectivityChanged,
          name: 'reconnect_max_retries_exceeded',
        ),
      );
      _cancelReconnectWorkflow();

      // Fallback to SFU if P2P failed
      if (_state.transport == IntercomTransport.p2p) {
        _emitTelemetry(
          IntercomTelemetryEvent.now(
            level: IntercomTelemetryLevel.warning,
            command: IntercomCommand.onConnectivityChanged,
            name: 'reconnect_fallback_to_sfu',
          ),
        );
        _cancelReconnectWorkflow();
        _switchToSfu(reason: IntercomDecisionReason.recovery);
        return;
      }

      _emitFailure(
        const IntercomFailure(
          code: IntercomFailureCode.reconnectTtlExceeded,
          message: 'Baglanti saglanamadi (Max deneme asildi)',
          recoverable: false,
        ),
      );
      return;
    }

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

    // [NEW] ICE Restart Entegrasyonu
    // Baglanti koptugunda P2P modundaysak once ICE Restart deneyerek hizli toparlanma sagla
    if (_state.transport == IntercomTransport.p2p && _p2pPeerUserId != null) {
        final offer = await webRTCService.restartIce();
        if (offer != null && offer.sdp != null) {
            await signalRService.sendOffer(_p2pPeerUserId!, offer.sdp!);
        } else {
            await _evaluateTransport(reason: IntercomDecisionReason.recovery);
        }
    } else {
        await _evaluateTransport(reason: IntercomDecisionReason.recovery);
    }

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
    _transportOverlapTimer?.cancel();

    _p2pDebounceTimer = null;
    _sfuToP2pTimer = null;
    _reconnectRetryTimer = null;
    _transportOverlapTimer = null;
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

  // [NEW] Helper to cancel overlapping switch timers
  void _cancelPendingSwitches() {
    _sfuToP2pTimer?.cancel();
    _p2pDebounceTimer?.cancel();
    _p2pToSfuHysteresisTimer?.cancel();

    _sfuToP2pTimer = null;
    _p2pDebounceTimer = null;
    _p2pToSfuHysteresisTimer = null;
  }

  // [NEW] Pre-fetch Token
  Future<void> _prefetchLiveKitToken() async {
    // Only prefetch if cache is empty or old
    if (_cachedLiveKitToken != null && _tokenTimestamp != null) {
      final age = DateTime.now().difference(_tokenTimestamp!);
      if (age < _tokenTtl) return; // Valid cache exists
    }

    final context = _context;
    if (context == null) return;

    try {
      final tokenData = await liveKitApi.getToken(
        roomName: context.roomName,
        identity: context.localUserId.toString(),
        displayName: _contextDisplayName(context),
      );
      final token = tokenData['token'];
      if (token != null && token.isNotEmpty) {
        _cachedLiveKitToken = token;
        _tokenTimestamp = DateTime.now();
      }
    } catch (e) {
      // Ignore pre-fetch errors
    }
  }
}
