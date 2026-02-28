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
  StreamSubscription? _webRtcQualitySub;
  StreamSubscription? _webRtcMetricsSub;
  StreamSubscription? _adaptiveBitrateSub;
  // Telefon araması / Siri / alarm gibi OS audio interruption olayları
  StreamSubscription? _audioInterruptionSub;

  // [ICE-BATCH] ICE candidate göndermede batching
  //
  // 5–15 ICE candidate'in her biri için tek tek SignalR mesajı göndermek yerine
  // 150ms'lik bir pencere açılır. Bu süre içinde biriken tüm candidate'ler
  // SendIceCandidatesBatch ile tek seferde iletilir. Peer tarafında
  // ReceiveIceCandidatesBatch, her candidate'i ayrı ayrı WebRTC'ye besler.
  final List<Map<String, dynamic>> _iceBatchBuffer = [];
  Timer? _iceBatchTimer;
  static const Duration _iceBatchWindow = Duration(milliseconds: 150);

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

  // [PRE-WARM] SFU→P2P geçişinde WebRTC arka planda ısındırma
  //
  // _sfuToP2pTimer başlatıldığı anda WebRTC donanımını (ICE fetch + PeerConnection
  // init + mikrofon) arka planda hazırlarız. sfuToP2pDelay (3 sn) bittiğinde
  // _switchToP2p() bu pre-warm'u hazır bulur ve _prepareWebRtcForOffer()'ı
  // tekrar çağırmaz — bağlantı anında kurulur.
  Future<void>? _sfuToP2pPrewarmFuture;
  bool _webRtcPrewarmed = false;

  // [NEW] Token Caching
  String? _cachedLiveKitToken;
  String? _cachedLiveKitUrl;
  DateTime? _tokenTimestamp;
  static const Duration _tokenTtl = Duration(minutes: 30);

  // [ICE-REFRESH] ICE server proaktif önbelleği
  //
  // TTL = 55 dk (TURN credential'larının tipik ömrüne yakın, ama biraz kısa).
  // attachSession() çağrıldığı anda cache boşsa ya da TTL'nin son 5 dakikasındaysa
  // _proactivelyRefreshIceServers() arka planda yeniler. Bu sayede
  // _prepareWebRtcForOffer() çağrıldığında cache her zaman sıcak olur.
  List<Map<String, dynamic>>? _cachedIceServers;
  DateTime? _iceServerTimestamp;
  static const Duration _iceServerTtl = Duration(minutes: 55);
  // Yenileme penceresi: TTL dolmadan bu kadar süre önce arka planda yenile.
  static const Duration _iceServerRefreshMargin = Duration(minutes: 5);

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
    _subscribeAudioSession(); // [NEW] OS audio interruption recovery

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

    // [ICE-REFRESH] Session'a bağlanılır bağlanılmaz ICE sunucularını arka planda
    // hazırla. 2. katılımcı gelip P2P başlatıldığında cache sıcak olur → 0 gecikme.
    unawaited(_proactivelyRefreshIceServers());

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
    await _lkQualitySub?.cancel();

    await _headlessRequestSub?.cancel();
    await _headlessAcceptedSub?.cancel();
    await _headlessEndedSub?.cancel();
    await _headlessFailedSub?.cancel();
    _headlessCallTimeoutTimer?.cancel();
    await _offerSub?.cancel();
    await _answerSub?.cancel();
    await _iceSub?.cancel();
    _iceBatchTimer?.cancel();
    _iceBatchBuffer.clear();

    await _webRtcIceSub?.cancel();
    await _webRtcConnectionSub?.cancel();
    await _webRtcQualitySub?.cancel();
    await _webRtcMetricsSub?.cancel();
    await _adaptiveBitrateSub?.cancel();
    await _audioInterruptionSub?.cancel();

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
    _webRtcIceSub = webRTCService.onIceCandidate$.listen((candidate) {
      // [ICE-BATCH] Her candidate'i buffer'a ekle; 150ms sonra hepsini tek mesajda gönder.
      _iceBatchBuffer.add({
        'candidate': candidate.candidate ?? '',
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
      _iceBatchTimer ??= Timer(_iceBatchWindow, _flushIceCandidateBatch);
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

    _webRtcQualitySub?.cancel();
    _webRtcQualitySub = webRTCService.connectionQualityStream.listen((quality) {
      final normalized = quality.toUpperCase();
      final mapped = normalized == 'POOR'
          ? IntercomConnectionQuality.poor
          : IntercomConnectionQuality.good;
      _bitrateController.onQualityChanged(mapped);
    });

    _webRtcMetricsSub?.cancel();
    _webRtcMetricsSub = webRTCService.networkMetricsStream.listen((metrics) {
      _bitrateController.onNetworkMetrics(
        packetLossPercent: metrics.packetLossPercent,
        jitterMs: metrics.jitterMs,
        rttMs: metrics.rttMs,
      );

      _emitTelemetry(
        IntercomTelemetryEvent.now(
          command: IntercomCommand.onAudioSettingsChanged,
          name: 'adaptive_bitrate.metrics',
          data: {
            'transport': 'p2p',
            'packetLossPercent': metrics.packetLossPercent,
            'jitterMs': metrics.jitterMs,
            'rttMs': metrics.rttMs,
            'effectiveBitrate': _bitrateController.effectiveBitrate,
            'ceiling': _bitrateController.ceilingBitrate,
          },
        ),
      );
    });
  }

  // ============================================================
  // AUDIO SESSION — OS Interruption Recovery
  // ============================================================
  //
  // iOS ve Android'de telefon araması / Siri / alarm gibi sistem events'leri
  // audio session'ı askıya alır. Bu metot ilgili stream'e abone olarak:
  //   • Kesinti başlayınca → reconnecting state'e girer (bağlantıyı koparma,
  //     OS zaten I/O'yu duraklatır; timer TTL içinde retry başlar).
  //   • Kesinti bitince → session'ı yeniden aktifleştirir + transport recovery.
  //
  // Neden bağlantıyı kesmiyoruz?
  //   Tipik telefon araması 1–3 dk sürer. Bağlantı koparılırsa karşı tarafın
  //   reconnect döngüsü de tetiklenir → çift gürültü + bağlantı gecikmesi.
  //   Bunun yerine "sessiz bekleme + otomatik recovery" tercih edildi.

  void _subscribeAudioSession() {
    _audioInterruptionSub?.cancel();
    _audioInterruptionSub = audioOrchestratorService.interruptionStream.listen(
      (event) async {
        if (event.begin) {
          // ── Interruption Başladı ────────────────────────────────────────
          // Telefon araması, Siri, alarm vb. OS audio I/O'yu durdurdu.
          // Biz sadece state'i güncelliyoruz; gerçek I/O OS tarafından
          // zaten askıya alındı.
          _emitTelemetry(
            IntercomTelemetryEvent.now(
              level: IntercomTelemetryLevel.warning,
              command: IntercomCommand.onLifecycleChanged,
              name: 'audio.interruption.began',
              data: {
                'transport': _state.transport.name,
                'phase': _state.phase.name,
              },
            ),
          );

          // Aktif bir oturum varsa ve zaten reconnecting/idle değilsek
          // reconnecting'e geç — timer içinde otomatik retry başlar.
          if (_context != null &&
              _state.phase != IntercomPhase.idle &&
              _state.phase != IntercomPhase.reconnecting) {
            _enterReconnecting(reason: 'audio.interruption.began');
          }
        } else {
          // ── Interruption Bitti ──────────────────────────────────────────
          // Telefon araması kapandı / Siri bitti vb.
          // iOS, interruption bittikten sonra setActive(true) çağrılana dek
          // audio I/O'yu restore etmez (platform quirk). Bunu biz yapıyoruz.
          _emitTelemetry(
            IntercomTelemetryEvent.now(
              command: IntercomCommand.onLifecycleChanged,
              name: 'audio.interruption.ended',
              data: {
                'transport': _state.transport.name,
                'hasContext': _context != null,
              },
            ),
          );

          if (_context != null) {
            // Önce session'ı yeniden aktifleştir; sonra transport'u recovery
            // modunda başlat. Sırası önemli: setActive(true) olmadan
            // iOS'ta ses gelmez.
            await audioOrchestratorService.activateSession();
            _cancelReconnectWorkflow(); // Var olan retry döngüsünü temizle
            await _evaluateTransport(reason: IntercomDecisionReason.recovery);
          }
        }
      },
    );
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
      // [PRE-WARM] sfuToP2pDelay (3 sn) beklerken WebRTC donanımını
      // arka planda hazırla: ICE fetch + PeerConnection init + mikrofon.
      // Timer bitip _switchToP2p() çağrıldığında her şey hazır olur.
      _startSfuToP2pPrewarm();
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

    // [ADAPTIVE-DELAY] ICE cache sıcaksa kısa debounce (100ms), soğuksa tam 500ms.
    // Tek amaç: 3. katılımcının anlık çıkış/giriş fırtınasına karşı guard;
    // ICE fetch süresi yoksa 500ms beklemek gereksiz.
    final delay = _isIceCacheWarm()
        ? _policy.p2pDecisionDelayWarm
        : _policy.p2pDecisionDelay;

    _p2pDebounceTimer = Timer(delay, () {
      _switchToP2p(
        reason: IntercomDecisionReason.twoParticipantsP2p,
        delayApplied: delay,
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
        delayApplied: delay,
        at: DateTime.now(),
      ),
    );

    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.attachSession,
        name: 'p2p.decision_delay',
        data: {
          'delayMs': delay.inMilliseconds,
          'iceCacheWarm': _isIceCacheWarm(),
        },
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
    //
    // SFU→P2P geçişinde: _startSfuToP2pPrewarm() sayesinde WebRTC,
    // sfuToP2pDelay timer'dan önce zaten hazırlandı. Pre-warm bittiyse
    // _prepareWebRtcForOffer()'u atla; hâlâ sürüyorsa (nadir: aw yavaş ağ)
    // tamamlanmasını bekle. Direkt P2P geçişlerinde (SFU yoksa) burada yap.
    try {
      if (_sfuToP2pPrewarmFuture != null) {
        // Pre-warm hâlâ sürüyor — tamamlanmasını bekle
        await _sfuToP2pPrewarmFuture;
      }
      if (!_webRtcPrewarmed) {
        // SFU yokken direkt P2P ya da pre-warm başarısız oldu — burada yap
        await _prepareWebRtcForOffer();
      }
    } catch (e, stack) {
      _webRtcPrewarmed = false;
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
    } finally {
      // Pre-warm bayrağını sıfırla — bir sonraki geçişte temiz başlasın
      _webRtcPrewarmed = false;
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
      // ── Invitee Side Timeout ──────────────────────────────────────
      // [OFFER-FIRST] Host Offer'ı doğrudan gönderiyor. _onOffer() tetiklenince
      // _headlessCallTimeoutTimer iptal edilecek. Eğer 15s geçmeden Offer gelmezse
      // (host offline / ağ sorunu) reconnect'e düş.
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
    // [OFFER-FIRST] Headless istek artık yalnızca "host online" bilgisi taşıyor.
    // Invitee tarafında kritik yol _onOffer() üzerinden işliyor.
    // acceptHeadlessCall fire-and-forget: host kabul sinyalini beklemediği için
    // invitee tarafında ayrı bir timeout kurmak gerekmez.
    if (_state.transport != IntercomTransport.p2p) return;
    _p2pPeerUserId = callerId;
    unawaited(signalRService.acceptHeadlessCall(callerId));
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
    // [OFFER-FIRST] Host artık HeadlessAccepted sinyalini beklemeden Offer gönderiyor.
    // Bu callback kritik yolda değil. Gelirse timeout'u iptal et, telemetri logla.
    _headlessCallTimeoutTimer?.cancel();
    _emitTelemetry(
      IntercomTelemetryEvent.now(
        command: IntercomCommand.attachSession,
        name: 'offer_first.headless_accepted_late',
        data: {'peerId': userId},
      ),
    );
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
    _headlessCallTimeoutTimer?.cancel();
    _p2pPeerUserId = userId;
    try {
      if (_state.transport != IntercomTransport.p2p) return;

      // [OFFER-FIRST + PRE-WARM] Offer direkt geldi (headless handshake beklenmedi).
      // Invitee tarafında WebRTC pre-warm durumunu kontrol et:
      //  • SFU→P2P yolundaysa: _startSfuToP2pPrewarm() arka planda hazırlandı — bekle.
      //  • Direkt P2P / pre-warm başarısız: burada hazırla.
      if (_sfuToP2pPrewarmFuture != null) {
        await _sfuToP2pPrewarmFuture;
      }
      if (!_webRtcPrewarmed) {
        await _prepareWebRtcForOffer();
      }
      _webRtcPrewarmed = false;

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

  /// [ICE-BATCH] Buffer dolduğunda ya da 150ms geçtiğinde batch'ı gönderir.
  /// Peer tarafında ReceiveIceCandidatesBatch her candidate'ı ayrı ayrı WebRTC'ye besler.
  void _flushIceCandidateBatch() {
    _iceBatchTimer = null;
    final batch = List<Map<String, dynamic>>.from(_iceBatchBuffer);
    _iceBatchBuffer.clear();
    final target = _p2pPeerUserId;
    if (target == null || target.isEmpty || batch.isEmpty) return;
    unawaited(signalRService.sendIceCandidatesBatch(target, batch));
  }

  Future<void> _prepareWebRtcForOffer() async {
    // [ICE-REFRESH] Cache sıcaksa doğrudan kullan; TTL dolduysa hemen fetch et.
    List<Map<String, dynamic>> servers;
    if (_isIceCacheWarm()) {
      servers = _cachedIceServers!;
    } else {
      // Cache yok veya süresi doldu — senkron olarak yenile
      final ice = await liveKitApi.getIceServers();
      servers = (ice['iceServers'] as List?)?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      _cachedIceServers = servers;
      _iceServerTimestamp = DateTime.now();
    }

    await webRTCService.stopAll();
    await webRTCService.initialize(servers);
    await webRTCService.startLocalStream();
  }

  // ============================================================
  // SFU → P2P PRE-WARMING
  // ============================================================
  //
  // Akış:
  //   1. _evaluateTransport() → 2 katılımcı + SFU aktif
  //   2. _sfuToP2pTimer başlatılır (sfuToP2pDelay = 3 sn)
  //   3. _startSfuToP2pPrewarm() hemen çağrılır
  //   4. _runSfuToP2pPrewarm() arka planda: ICE fetch + WebRTC init + mikrofon
  //   5. 3 sn sonra timer biter → _switchToP2p() çağrılır
  //   6. _switchToP2p(): pre-warm bitmişse _prepareWebRtcForOffer()'ı atlar
  //      → donanım hazır, bağlantı anında kurulur (~0 ms ek gecikme)
  //
  // Timer iptal senaryosu (3. katılımcı gelirse):
  //   _cancelPendingSwitches() → _cancelSfuToP2pPrewarm() → stopAll()
  // ============================================================

  /// [PRE-WARM] SFU→P2P hysteresis timer başladığında çağrılır.
  /// Timer süresi boyunca WebRTC donanımını arka planda hazırlar.
  void _startSfuToP2pPrewarm() {
    if (_sfuToP2pPrewarmFuture != null) return; // Zaten çalışıyor
    _webRtcPrewarmed = false;
    _sfuToP2pPrewarmFuture = _runSfuToP2pPrewarm();
  }

  Future<void> _runSfuToP2pPrewarm() async {
    try {
      await _prepareWebRtcForOffer();
      _webRtcPrewarmed = true;
    } catch (_) {
      // Hata sessizce yutulur.
      // _switchToP2p() _webRtcPrewarmed=false görünce _prepareWebRtcForOffer()'ı
      // kendisi yeniden deneyecek ve hata orada raporlanacak.
      _webRtcPrewarmed = false;
    } finally {
      _sfuToP2pPrewarmFuture = null;
    }
  }

  /// Pre-warm sırasında başlatılan WebRTC kaynaklarını temizler.
  /// _cancelTimers() ve _cancelPendingSwitches() tarafından çağrılır:
  /// timer iptal edildiğinde boşta açık kalan donanım kapatılır.
  void _cancelSfuToP2pPrewarm() {
    if (_webRtcPrewarmed) {
      // Pre-warm tamamlandı ama switch iptal edildi → WebRTC'yi kapat
      webRTCService.stopAll();
      _webRtcPrewarmed = false;
    }
    // Future hâlâ sürüyorsa bitmesine izin ver; sonuç _webRtcPrewarmed=false
    // ile bitecek — _cancelPendingSwitches sonrası if bloğu çalışmaz.
    _sfuToP2pPrewarmFuture = null;
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
    _iceBatchTimer?.cancel();

    _p2pDebounceTimer = null;
    _sfuToP2pTimer = null;
    _reconnectRetryTimer = null;
    _transportOverlapTimer = null;
    _iceBatchTimer = null;
    _iceBatchBuffer.clear();

    // Timer iptal edildi — arka planda ısınan WebRTC kaynaklarını temizle
    _cancelSfuToP2pPrewarm();
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

    // Timer iptal edildi — arka planda ısınan WebRTC kaynaklarını temizle
    _cancelSfuToP2pPrewarm();
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

  // ============================================================
  // ICE SERVER PROAKTİF REFRESH
  // ============================================================
  //
  // Neden gerekli?
  //   TURN credential'ların ömrü dolduğunda (veya cache hiç dolu olmadığında)
  //   _prepareWebRtcForOffer() içinde senkron bir HTTP isteği yapılmak zorunda
  //   kalınır. Bu 200–500ms ek gecikme demektir.
  //
  // Çözüm:
  //   attachSession() çağrıldığı anda cache'i kontrol et; boşsa veya TTL'nin
  //   son _iceServerRefreshMargin (5 dk) içindeyse arka planda hemen yenile.
  //   P2P bağlantısı başladığında cache her zaman sıcak olur.
  // ============================================================

  /// ICE server cache'inin geçerli ve sıcak olup olmadığını döndürür.
  bool _isIceCacheWarm() {
    if (_cachedIceServers == null || _cachedIceServers!.isEmpty) return false;
    if (_iceServerTimestamp == null) return false;
    final age = DateTime.now().difference(_iceServerTimestamp!);
    return age < _iceServerTtl - _iceServerRefreshMargin;
  }

  /// ICE sunucularını arka planda proaktif olarak yeniler.
  ///
  /// Cache boşsa veya TTL'nin son 5 dakikasındaysa fetch yapar.
  /// Hata durumunda sessizce devam eder — eski/boş cache varsa
  /// _prepareWebRtcForOffer() yine de fallback fetch yapabilir.
  Future<void> _proactivelyRefreshIceServers() async {
    if (_isIceCacheWarm()) return; // Cache zaten sıcak — gerek yok

    try {
      final ice = await liveKitApi.getIceServers();
      final servers = (ice['iceServers'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];

      if (servers.isNotEmpty) {
        _cachedIceServers = servers;
        _iceServerTimestamp = DateTime.now();
        _emitTelemetry(
          IntercomTelemetryEvent.now(
            command: IntercomCommand.attachSession,
            name: 'ice.proactive_refresh_ok',
            data: {'serverCount': servers.length},
          ),
        );
      }
    } catch (e) {
      // Hata sessizce loglanır; _prepareWebRtcForOffer() fallback yapar.
      _emitTelemetry(
        IntercomTelemetryEvent.now(
          level: IntercomTelemetryLevel.warning,
          command: IntercomCommand.attachSession,
          name: 'ice.proactive_refresh_failed',
          data: {'error': e.toString()},
        ),
      );
    }
  }
}
