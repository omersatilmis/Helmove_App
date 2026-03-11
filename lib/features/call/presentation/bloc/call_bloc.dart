import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/services/callkit_incoming_service.dart'; // Added
import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/webrtc_service.dart';
import '../../../../core/services/permissions_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/call_entities.dart';
import '../../domain/usecases/call_usecases.dart';
import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final SignalRService signalRService;
  final WebRTCService webRTCService;
  final PermissionsService permissionsService;
  final SendCallRequestUseCase sendCallRequestUseCase;
  final AcceptCallUseCase acceptCallUseCase;
  final RejectCallUseCase rejectCallUseCase;
  final EndCallUseCase endCallUseCase;
  final GetPendingCallsUseCase getPendingCallsUseCase;
  final CallKitIncomingService callKitIncomingService; // Added

  String? _activeCallKitId;

  int? _remoteUserId;
  int? _currentCallId;

  StreamSubscription? _connectionStateSub;
  StreamSubscription? _iceCandidateSub;

  StreamSubscription? _incomingCallSub;
  StreamSubscription? _callAcceptedSub;
  StreamSubscription? _callRejectedSub;
  StreamSubscription? _callEndedSub;
  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _iceCandidateSignalRSub;
  StreamSubscription? _callRequestFailedSub;
  StreamSubscription? _callActionFailedSub;
  StreamSubscription? _signalDeliveryFailedSub;

  Timer? _callTimer;
  Timer? _outgoingTimeoutTimer;
  Timer? _connectingTimeoutTimer;
  Duration _callDuration = Duration.zero;
  Future<void> _signalingQueue = Future.value();
  Future<void>? _cleanupFuture;
  bool _isLocalHangupInProgress = false;
  String? _lastRemoteOfferSdp;
  String? _lastRemoteAnswerSdp;
  bool _hasLocalOffer = false;
  int? _lastAcceptedByRemoteUserId;
  DateTime? _lastAcceptedByRemoteAt;

  static const Duration _outgoingTimeout = Duration(seconds: 35);
  static const Duration _connectingTimeout = Duration(seconds: 30);

  CallBloc({
    required this.signalRService,
    required this.webRTCService,
    required this.permissionsService,
    required this.sendCallRequestUseCase,
    required this.acceptCallUseCase,
    required this.rejectCallUseCase,
    required this.endCallUseCase,
    required this.getPendingCallsUseCase,
    required this.callKitIncomingService, // Added
  }) : super(const CallInitial()) {
    on<CallRequested>(_onCallRequested);
    on<CallIncomingReceived>(_onCallIncomingReceived);
    on<CallAccepted>(_onCallAccepted);
    on<CallRejected>(_onCallRejected);
    on<CallAcceptedByRemote>(_onCallAcceptedByRemote);
    on<CallRejectedByRemote>(_onCallRejectedByRemote);
    on<OfferReceived>(_onOfferReceived);
    on<AnswerReceived>(_onAnswerReceived);
    on<IceCandidateReceived>(_onIceCandidateReceived);
    on<CallHangUp>(_onCallHangUp);
    on<CallEndedByRemote>(_onCallEndedByRemote);
    on<CallToggleMicrophone>(_onToggleMicrophone);
    on<CallConnectionStateChanged>(_onConnectionStateChanged);
    on<CallSignalingFailed>(_onCallSignalingFailed);
    on<CallOutgoingTimeoutReached>(_onCallOutgoingTimeoutReached);
    on<CallConnectingTimeoutReached>(_onCallConnectingTimeoutReached);
    on<CallDurationTicked>(_onCallDurationTicked);
    on<CallAppResumedSyncRequested>(_onAppResumedSyncRequested);

    _subscribeToSignalRStreams();
  }

  Future<void> _onAppResumedSyncRequested(
    CallAppResumedSyncRequested event,
    Emitter<CallState> emit,
  ) async {
    if (state is CallActive || state is CallConnecting || state is CallIncoming) {
      // Zaten bir arama akışındaysak (aktif veya çalıyor), sync'e gerek yok;
      // akışın devam etmesine izin ver.
      return;
    }

    try {
      AppLogger.info('CallBloc: App resumed, checking for missed pending calls...');
      final pendingCalls = await getPendingCallsUseCase.execute();
      if (pendingCalls.isNotEmpty) {
        final latest = pendingCalls.last;
        // Eğer uygulama kapalıyken (SignalR yokken) bir call gelmişse
        // buradan yakalayıp UI'ı tetikleyebiliriz.
        AppLogger.info('CallBloc: Missed pending call found: id=${latest.callId}');
        
        add(CallIncomingReceived(
          callerId: latest.callerId,
          callerDisplayName: 'Gelen Arama', // CallResponseEntity'de displayName yok, placeholder atıyoruz
          callId: latest.callId,
        ));
      }
    } catch (e) {
      AppLogger.warning('CallBloc: App resume sync failed: $e');
    }
  }

  void _subscribeToSignalRStreams() {
    _incomingCallSub = signalRService.incomingCallStream.listen((payload) {
      if (isClosed) return;

      final callerId = int.tryParse(payload.callerId) ?? -1;
      if (callerId <= 0) {
        AppLogger.warning(
          'CallBloc: Incoming call ignored, invalid caller id. Payload: $payload',
        );
        return;
      }

      add(
        CallIncomingReceived(
          callerId: callerId,
          callerDisplayName: payload.callerDisplayName,
          callId: payload.callId,
        ),
      );
    });

    _callAcceptedSub = signalRService.callAcceptedStream.listen((payload) {
      if (isClosed) return;
      final acceptedByUserId = int.tryParse(payload.actorId) ?? -1;
      if (acceptedByUserId <= 0) {
        AppLogger.warning('CallBloc: CallAccepted ignored, invalid actor id.');
        return;
      }
      add(CallAcceptedByRemote(targetUserId: acceptedByUserId));
    });

    _callRejectedSub = signalRService.callRejectedStream.listen((payload) {
      if (isClosed) return;
      final rejectedByUserId = int.tryParse(payload.actorId) ?? -1;
      if (rejectedByUserId <= 0) {
        AppLogger.warning('CallBloc: CallRejected ignored, invalid actor id.');
        return;
      }
      add(
        CallRejectedByRemote(
          targetUserId: rejectedByUserId,
          reason: payload.reason,
        ),
      );
    });

    _callEndedSub = signalRService.callEndedStream.listen((payload) {
      if (isClosed) return;
      final endedByUserId = int.tryParse(payload.actorId) ?? -1;
      // targetUserId might be null or string
      final targetUserId = int.tryParse(payload.targetUserId ?? '') ?? -1;

      add(
        CallEndedByRemote(
          targetUserId: targetUserId,
          endedByUserId: endedByUserId,
        ),
      );
    });

    _offerSub = signalRService.offerStream.listen((payload) {
      if (isClosed) return;

      final callerId = int.tryParse(payload.userId) ?? -1;
      final sdp = payload.sdp;

      if (callerId <= 0 ||
          sdp.trim().isEmpty ||
          !sdp.trimLeft().startsWith('v=')) {
        AppLogger.warning(
          'CallBloc: Offer ignored, invalid payload. '
          'callerId=$callerId sdpEmpty=${sdp.trim().isEmpty}',
        );
        return;
      }
      AppLogger.info('CallBloc: Offer received sdpLen=${sdp.length}');

      add(OfferReceived(callerId: callerId, sdp: sdp));
    });

    _answerSub = signalRService.answerStream.listen((payload) {
      if (isClosed) return;

      final targetUserId = int.tryParse(payload.userId) ?? -1;
      final sdp = payload.sdp;

      if (targetUserId <= 0 ||
          sdp.trim().isEmpty ||
          !sdp.trimLeft().startsWith('v=')) {
        AppLogger.warning(
          'CallBloc: Answer ignored, invalid payload. '
          'targetUserId=$targetUserId sdpEmpty=${sdp.trim().isEmpty} ',
        );
        return;
      }
      AppLogger.info('CallBloc: Answer received sdpLen=${sdp.length}');

      add(AnswerReceived(targetUserId: targetUserId, sdp: sdp));
    });

    _iceCandidateSignalRSub = signalRService.iceCandidateStream.listen((
      payload,
    ) {
      if (isClosed) return;

      final fromUserId = int.tryParse(payload.fromUserId) ?? -1;
      final candidate = payload.candidate;

      if (fromUserId <= 0 || candidate.isEmpty) {
        AppLogger.warning(
          'CallBloc: ICE ignored, invalid payload. fromUserId=$fromUserId candidateEmpty=${candidate.isEmpty}',
        );
        return;
      }

      add(
        IceCandidateReceived(
          fromUserId: fromUserId,
          candidate: candidate,
          sdpMid: payload.sdpMid,
          sdpMLineIndex: payload.sdpMLineIndex,
        ),
      );
    });

    _callRequestFailedSub = signalRService.callRequestFailedStream.listen((
      message,
    ) {
      if (isClosed) return;
      add(CallSignalingFailed(message: message));
    });

    _callActionFailedSub = signalRService.callActionFailedStream.listen((
      message,
    ) {
      if (isClosed) return;
      add(CallSignalingFailed(message: message));
    });

    _signalDeliveryFailedSub = signalRService.signalDeliveryFailedStream.listen(
      (phase) {
        if (isClosed) return;
        add(CallSignalingFailed(message: 'Sinyal iletimi basarisiz: $phase'));
      },
    );
  }

  Future<void> _onCallRequested(
    CallRequested event,
    Emitter<CallState> emit,
  ) async {
    final permissionsOk = await permissionsService.ensureCallPermissions();
    if (!permissionsOk) {
      emit(const CallError(message: 'Arama icin gerekli izinler verilmedi'));
      return;
    }

    _remoteUserId = event.targetUserId;
    _currentCallId = null;
    _resetSignalingSessionState();
    final request = CallRequestEntity(
      targetUserId: event.targetUserId,
      callType: 'voice',
    );

    try {
      AppLogger.info('CallBloc: Starting call -> ${event.targetUserId}');
      if (!signalRService.isConnected) {
        await signalRService.init();
      }
      if (!signalRService.isConnected) {
        throw Exception(
          'SignalR baglantisi kurulamadigi icin arama baslatilamadi',
        );
      }

      final result = await sendCallRequestUseCase.execute(request);
      _currentCallId = result.callId;

      // START CALLKIT & PLAY TONE
      final uuid = callKitIncomingService.generateCallKitId();
      _activeCallKitId = uuid;
      await callKitIncomingService.startOutboundCall(
        uuid: uuid,
        handle: event.targetDisplayName ?? "Kullanıcı",
        nameCaller: event.targetDisplayName ?? "Sesli Arama",
      );
      await callKitIncomingService.playOutgoingTone();

      // Backend REST zaten istegi olusturuyor; yine de Hub uzerinden
      // explicit call request gondererek SignalR routing/state tarafini saglama al.
      try {
        await signalRService.sendCallRequest(event.targetUserId.toString());
      } catch (e) {
        AppLogger.warning(
          'CallBloc: SignalR sendCallRequest fallback failed: $e',
        );
      }

      emit(
        CallOutgoing(
          targetUserId: event.targetUserId,
          targetDisplayName: event.targetDisplayName,
        ),
      );
      _startOutgoingTimeout();
    } catch (e) {
      final errorMessage = e.toString();
      AppLogger.error('CallBloc: Start call failed', e);

      if (_isAlreadyActiveCallError(errorMessage)) {
        final recovered = await _recoverActiveCallConflict(
          request: request,
          targetUserId: event.targetUserId,
        );

        if (recovered != null) {
          _currentCallId = recovered.callId;
          try {
            await signalRService.sendCallRequest(event.targetUserId.toString());
          } catch (e) {
            AppLogger.warning(
              'CallBloc: SignalR sendCallRequest retry after recovery failed: $e',
            );
          }
          emit(
            CallOutgoing(
              targetUserId: event.targetUserId,
              targetDisplayName: event.targetDisplayName,
            ),
          );
          _startOutgoingTimeout();
          return;
        }
      }

      emit(CallError(message: 'Arama baslatilamadi: $errorMessage'));
    }
  }

  Future<void> _onCallIncomingReceived(
    CallIncomingReceived event,
    Emitter<CallState> emit,
  ) async {
    _remoteUserId = event.callerId;
    _resetSignalingSessionState();

    emit(
      CallIncoming(
        callerId: event.callerId,
        callerDisplayName: event.callerDisplayName,
      ),
    );

    // [NEW] CallKit: Show incoming UI (WhatsApp Style lock screen)
    try {
      final uuid = _activeCallKitId ?? callKitIncomingService.generateCallKitId();
      _activeCallKitId = uuid;
      
      unawaited(callKitIncomingService.showIncomingCall(
        CallInvitePayload(
          callKitId: uuid,
          callerId: event.callerId,
          callerDisplayName: event.callerDisplayName ?? 'Gelen Arama',
          callId: event.callId,
        ),
      ));
    } catch (e) {
      AppLogger.warning('CallBloc: CallKit show failed: $e');
    }

    if (event.callId != null) {
      _currentCallId = event.callId;
      return;
    }

    try {
      final pendingCalls = await getPendingCallsUseCase.execute();
      final match = pendingCalls.firstWhere(
        (c) => c.callerId == event.callerId,
        orElse: () => throw Exception('Pending call not found for caller'),
      );
      _currentCallId = match.callId;
    } catch (e) {
      AppLogger.error(
        'CallBloc: Could not recover callId for incoming call',
        e,
      );
    }
  }

  Future<void> _onCallAccepted(
    CallAccepted event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _enqueueSignaling('CallAccepted', () async {
        final permissionsOk = await permissionsService.ensureCallPermissions();
        if (!permissionsOk) {
          emit(
            const CallError(message: 'Arama icin gerekli izinler verilmedi'),
          );
          return;
        }

        final remoteUserId = _remoteUserId;
        if (remoteUserId == null || remoteUserId <= 0) return;

        if (_currentCallId == null) {
          try {
            final pendingCalls = await getPendingCallsUseCase.execute();
            final match = pendingCalls.firstWhere(
              (c) =>
                  c.callerId == remoteUserId || c.targetUserId == remoteUserId,
              orElse: () =>
                  throw Exception('Pending call not found for accept'),
            );
            _currentCallId = match.callId;
          } catch (e) {
            AppLogger.warning(
              'CallBloc: Accept without callId recovery failed: $e',
            );
          }
        }

        if (_currentCallId != null) {
          await acceptCallUseCase.execute(_currentCallId!);
        }

        // START CALLKIT (Incoming answered)
        final uuid = callKitIncomingService.generateCallKitId();
        _activeCallKitId = uuid;
        await callKitIncomingService.startOutboundCall(
          uuid: uuid,
          handle: "Sesli Arama",
          nameCaller: "Sesli Arama",
        );

        emit(CallConnecting(remoteUserId: remoteUserId));
        _cancelOutgoingTimeout();
        _startConnectingTimeout();
        await _initializeWebRTC();

        try {
          if (!signalRService.isConnected) {
            await signalRService.init();
          }
          await signalRService.acceptCall(remoteUserId.toString());
        } catch (e) {
          AppLogger.warning('CallBloc: SignalR accept fallback failed: $e');
        }

        if (!signalRService.isConnected) {
          await signalRService.init();
        }
        // Callee sadece kabul eder ve offer bekler.
        // Offer üretimi caller tarafında CallAcceptedByRemote ile başlatılır.
        _hasLocalOffer = false;
        _lastRemoteAnswerSdp = null;
        AppLogger.info(
          'CallBloc: Incoming call accepted; waiting for remote offer.',
        );
      });
    } catch (e) {
      AppLogger.error('CallBloc: Accept call failed', e);
      emit(CallError(message: 'Baglanti kurulamadi: $e'));
    }
  }

  Future<void> _onCallRejected(
    CallRejected event,
    Emitter<CallState> emit,
  ) async {
    final remoteUserId = _remoteUserId;
    if (remoteUserId == null) {
      AppLogger.warning('CallBloc: _onCallRejected skipped; remoteUserId is null.');
      return;
    }

    // ── [REJECT FALLBACK] ──────────────────────────────────────────────────
    // Kullanıcı 'Reddet' butonuna bastığında SignalR bağlı olmasa bile 
    // REST API üzerinden (RejectCallUseCase) bildirimi diğer tarafa ulaştırmalıyız.
    // Bu sayede karşı tarafta "Arama Çalıyor" ekranı kalmaz, kapanır.
    
    if (_currentCallId != null && _currentCallId! > 0) {
      try {
        AppLogger.info('CallBloc: Rejecting call via REST API id=$_currentCallId');
        await rejectCallUseCase.execute(_currentCallId!);
      } catch (e) {
        AppLogger.warning(
          'CallBloc: Reject call via REST failed, fallback to safe end: $e',
        );
      }
    }

    // Ek olarak SignalR üzerinden de anlık sinyal gönder (bağlıysa)
    try {
      if (signalRService.isConnected) {
         await signalRService.rejectCall(remoteUserId.toString());
      }
    } catch (e) {
      AppLogger.warning('CallBloc: SignalR reject fallback failed: $e');
    }

    await _safeEndCurrentCall(remoteUserId: remoteUserId);
    await callKitIncomingService.stopOutgoingTone();
    await _cleanupCall();
    emit(const CallEnded(reason: 'Arama reddedildi'));
  }

  Future<void> _onCallAcceptedByRemote(
    CallAcceptedByRemote event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _enqueueSignaling('CallAcceptedByRemote', () async {
        final remoteUserId = _remoteUserId ?? event.targetUserId;
        if (remoteUserId <= 0) {
          throw Exception('Remote user id is invalid on CallAcceptedByRemote');
        }

        final now = DateTime.now();
        final isDuplicateAcceptSignal =
            _lastAcceptedByRemoteUserId == remoteUserId &&
            _lastAcceptedByRemoteAt != null &&
            now.difference(_lastAcceptedByRemoteAt!) <
                const Duration(seconds: 5);
        if (_hasLocalOffer || isDuplicateAcceptSignal) {
          AppLogger.warning(
            'CallBloc: Duplicate CallAcceptedByRemote ignored. '
            'remote=$remoteUserId hasLocalOffer=$_hasLocalOffer',
          );
          return;
        }
        _lastAcceptedByRemoteUserId = remoteUserId;
        _lastAcceptedByRemoteAt = now;

        AppLogger.info(
          'CallBloc: CallAcceptedByRemote signal=${event.targetUserId}, resolvedRemote=$remoteUserId',
        );

        emit(CallConnecting(remoteUserId: remoteUserId));
        _cancelOutgoingTimeout();
        _startConnectingTimeout();
        await _initializeWebRTC();

        if (!signalRService.isConnected) {
          await signalRService.init();
        }
        if (!signalRService.isConnected) {
          throw Exception('SignalR not connected while sending offer');
        }

        final offer = await webRTCService.createOffer();
        final offerSdp = offer.sdp ?? '';
        if (offerSdp.trim().isEmpty) {
          throw Exception('Local offer SDP is empty');
        }
        AppLogger.info(
          'CallBloc: Local offer created sdpLen=${offerSdp.length}',
        );
        _hasLocalOffer = true;
        _lastRemoteAnswerSdp = null;
        await signalRService.sendOffer(remoteUserId.toString(), offerSdp);
        AppLogger.info('CallBloc: SDP Offer sent (caller-initiated)');
      });
    } catch (e) {
      AppLogger.error('CallBloc: CallAcceptedByRemote handling failed', e);
      emit(CallError(message: 'Baglanti kurulamadi: $e'));
    }
  }

  Future<void> _onCallRejectedByRemote(
    CallRejectedByRemote event,
    Emitter<CallState> emit,
  ) async {
    await _safeEndCurrentCall(remoteUserId: event.targetUserId);
    await _cleanupCall();
    await callKitIncomingService.stopOutgoingTone();
    emit(CallEnded(reason: event.reason ?? 'Arama reddedildi'));
  }

  Future<void> _onOfferReceived(
    OfferReceived event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _enqueueSignaling('OfferReceived', () async {
        if (_lastRemoteOfferSdp == event.sdp) {
          AppLogger.warning('CallBloc: Duplicate offer ignored.');
          return;
        }

        _remoteUserId ??= event.callerId;
        if (state is! CallConnecting && state is! CallActive) {
          emit(CallConnecting(remoteUserId: _remoteUserId ?? event.callerId));
        }
        _cancelOutgoingTimeout();
        _startConnectingTimeout();

        if (!webRTCService.isInitialized) {
          AppLogger.warning(
            'CallBloc: Offer geldi ama peer hazir degil, WebRTC init ediliyor...',
          );
          await _initializeWebRTC();
        }

        await webRTCService.setRemoteDescription('offer', event.sdp);
        _lastRemoteOfferSdp = event.sdp;

        final answer = await webRTCService.createAnswer();
        final answerSdp = answer.sdp ?? '';
        if (answerSdp.trim().isEmpty) {
          throw Exception('Local answer SDP is empty');
        }
        AppLogger.info(
          'CallBloc: Local answer created sdpLen=${answerSdp.length}',
        );
        _hasLocalOffer = false;

        if (!signalRService.isConnected) {
          await signalRService.init();
        }
        if (!signalRService.isConnected) {
          throw Exception('SignalR not connected while sending answer');
        }

        await signalRService.sendAnswer(event.callerId.toString(), answerSdp);
        AppLogger.info('CallBloc: SDP Answer sent');
      });
    } catch (e) {
      AppLogger.error('CallBloc: Offer handling failed', e);
      emit(CallError(message: 'SDP hatasi: $e'));
    }
  }

  Future<void> _onAnswerReceived(
    AnswerReceived event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _enqueueSignaling('AnswerReceived', () async {
        if (_lastRemoteAnswerSdp == event.sdp) {
          AppLogger.warning('CallBloc: Duplicate answer ignored.');
          return;
        }
        if (!_hasLocalOffer) {
          AppLogger.warning(
            'CallBloc: Answer ignored because local offer is not active.',
          );
          return;
        }

        await webRTCService.setRemoteDescription('answer', event.sdp);
        _lastRemoteAnswerSdp = event.sdp;
        _hasLocalOffer = false;
        AppLogger.info('CallBloc: Remote SDP answer set');
      });
    } catch (e) {
      AppLogger.error('CallBloc: Answer handling failed', e);
      emit(CallError(message: 'SDP hatasi: $e'));
    }
  }

  Future<void> _onIceCandidateReceived(
    IceCandidateReceived event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _enqueueSignaling('IceCandidateReceived', () async {
        await webRTCService.addIceCandidate(
          event.candidate,
          event.sdpMid,
          event.sdpMLineIndex,
        );
      });
    } catch (e) {
      AppLogger.error('CallBloc: Add ICE candidate failed', e);
    }
  }

  Future<void> _onCallHangUp(CallHangUp event, Emitter<CallState> emit) async {
    final hasActiveCallState =
        state is CallOutgoing ||
        state is CallIncoming ||
        state is CallConnecting ||
        state is CallActive;
    final hasCallContext =
        (_remoteUserId != null && _remoteUserId! > 0) ||
        (_currentCallId != null && _currentCallId! > 0);

    // CallKit timeout/ended gibi sinyaller arka arkaya gelebiliyor.
    // Aktif çağrı bağlamı yoksa bu HangUp'u yok sayarak duplicate terminal state'i engelle.
    if (!hasActiveCallState && !hasCallContext) {
      AppLogger.info('CallBloc: HangUp ignored (no active call context)');
      return;
    }

    if (_isLocalHangupInProgress) {
      AppLogger.warning('CallBloc: Duplicate local hangup ignored');
      return;
    }

    _isLocalHangupInProgress = true;
    final duration = _callDuration;

    final remoteUserId = _remoteUserId;
    try {
      await _safeEndCurrentCall(remoteUserId: remoteUserId);
    } catch (e) {
      AppLogger.warning('CallBloc: HangUp end call fallback failed: $e');
    }

    await _cleanupCall();
    await callKitIncomingService.stopOutgoingTone();
    emit(CallEnded(reason: 'Aramayı sonlandırdınız.', callDuration: duration));
  }

  Future<void> _onCallEndedByRemote(
    CallEndedByRemote event,
    Emitter<CallState> emit,
  ) async {
    if (_isLocalHangupInProgress) {
      AppLogger.info(
        'CallBloc: Remote ended event ignored during local hangup. '
        'endedBy=${event.endedByUserId} target=${event.targetUserId}',
      );
      return;
    }

    final activeRemoteUserId = _remoteUserId;
    if (activeRemoteUserId == null || activeRemoteUserId <= 0) {
      AppLogger.warning(
        'CallBloc: Remote ended event ignored because there is no active remote user. '
        'endedBy=${event.endedByUserId} target=${event.targetUserId}',
      );
      return;
    }

    if (event.endedByUserId > 0 && event.endedByUserId != activeRemoteUserId) {
      AppLogger.warning(
        'CallBloc: Remote ended event ignored due to endedBy mismatch. '
        'expected=$activeRemoteUserId endedBy=${event.endedByUserId}',
      );
      return;
    }

    if (event.targetUserId > 0 && event.targetUserId != activeRemoteUserId) {
      AppLogger.warning(
        'CallBloc: Remote ended event ignored due to user mismatch. '
        'expected=$activeRemoteUserId incoming=${event.targetUserId}',
      );
      return;
    }

    final duration = _callDuration;
    // Remote taraf sonlandırdıysa tekrar "EndCall" sinyali yollamayalım (ping-pong yapabilir).
    await _safeEndCurrentCall(
      remoteUserId: activeRemoteUserId,
      signalREnd: false,
    );
    await _cleanupCall();
    await callKitIncomingService.stopOutgoingTone();
    emit(
      CallEnded(
        reason: 'Arama karşı taraf tarafından sonlandırıldı.',
        callDuration: duration,
      ),
    );
  }

  void _onToggleMicrophone(
    CallToggleMicrophone event,
    Emitter<CallState> emit,
  ) {
    webRTCService.toggleMicrophone();

    if (state is CallActive) {
      emit(
        (state as CallActive).copyWith(
          isMicrophoneOn: webRTCService.isMicrophoneOn,
        ),
      );
    }
  }

  Future<void> _onConnectionStateChanged(
    CallConnectionStateChanged event,
    Emitter<CallState> emit,
  ) async {
    final remoteUserId = _remoteUserId;
    if (remoteUserId == null || remoteUserId <= 0) return;

    if (event.state == 'connected') {
      _cancelOutgoingTimeout();
      _cancelConnectingTimeout();
      _startCallTimer();

      // MARK CONNECTED
      if (_activeCallKitId != null) {
        await callKitIncomingService.markConnected(_activeCallKitId!);
      }

      emit(CallActive(remoteUserId: remoteUserId));
      return;
    }

    if (event.state == 'failed') {
      await _safeEndCurrentCall(remoteUserId: remoteUserId);
      await _cleanupCall();
      emit(const CallEnded(reason: 'Baglanti kurulamadi'));
    }
  }

  Future<void> _onCallSignalingFailed(
    CallSignalingFailed event,
    Emitter<CallState> emit,
  ) async {
    if (state is CallInitial || state is CallEnded || state is CallError) {
      return;
    }

    AppLogger.warning('CallBloc: Signaling failure -> ${event.message}');
    await _safeEndCurrentCall(remoteUserId: _remoteUserId);
    await _cleanupCall();
    emit(CallError(message: event.message));
  }

  Future<void> _onCallOutgoingTimeoutReached(
    CallOutgoingTimeoutReached event,
    Emitter<CallState> emit,
  ) async {
    if (state is! CallOutgoing) return;

    AppLogger.warning('CallBloc: Outgoing call timeout reached');
    await _safeEndCurrentCall(remoteUserId: _remoteUserId);
    await _cleanupCall();
    emit(const CallEnded(reason: 'Arama yanitsiz kaldi'));
  }

  Future<void> _onCallConnectingTimeoutReached(
    CallConnectingTimeoutReached event,
    Emitter<CallState> emit,
  ) async {
    if (state is! CallConnecting) return;

    AppLogger.warning('CallBloc: Connecting timeout reached');
    await _safeEndCurrentCall(remoteUserId: _remoteUserId);
    await _cleanupCall();
    emit(const CallEnded(reason: 'Baglanti zaman asimina ugradi'));
  }

  void _onCallDurationTicked(
    CallDurationTicked event,
    Emitter<CallState> emit,
  ) {
    _callDuration += const Duration(seconds: 1);
    if (state is CallActive) {
      emit((state as CallActive).copyWith(callDuration: _callDuration));
    }
  }

  Future<void> _enqueueSignaling(
    String label,
    Future<void> Function() operation,
  ) {
    final next = _signalingQueue.then((_) async {
      if (isClosed) return;
      await operation();
    });

    _signalingQueue = next.catchError((Object error, StackTrace stackTrace) {
      AppLogger.error(
        'CallBloc: Signaling queue operation failed [$label]',
        error,
        stackTrace,
      );
    });

    return next;
  }

  void _resetSignalingSessionState() {
    _lastRemoteOfferSdp = null;
    _lastRemoteAnswerSdp = null;
    _hasLocalOffer = false;
    _lastAcceptedByRemoteUserId = null;
    _lastAcceptedByRemoteAt = null;
  }

  Future<void> _initializeWebRTC() async {
    final iceServers = await signalRService.fetchIceServers();
    await webRTCService.initialize(iceServers);
    await webRTCService.startLocalStream();

    await _iceCandidateSub?.cancel();
    _iceCandidateSub = webRTCService.onIceCandidate$.listen((candidate) {
      final remoteUserId = _remoteUserId;
      if (remoteUserId == null || remoteUserId <= 0) return;

      unawaited(
        signalRService
            .sendIceCandidate(
              remoteUserId.toString(),
              candidate.candidate ?? '',
              candidate.sdpMid,
              candidate.sdpMLineIndex,
            )
            .catchError((Object error, StackTrace stackTrace) {
              AppLogger.warning(
                'CallBloc: sendIceCandidate failed during stream callback: $error',
              );
            }),
      );
    });

    await _connectionStateSub?.cancel();
    _connectionStateSub = webRTCService.connectionState$.listen((rtcState) {
      if (isClosed) return;
      add(CallConnectionStateChanged(state: _rtcStateToString(rtcState)));
    });
  }

  bool _isAlreadyActiveCallError(String message) {
    final m = message.toLowerCase();
    return m.contains('zaten aktif bir araman') ||
        m.contains('zaten bir aramadas') ||
        m.contains('zaten aramadas') ||
        m.contains('already in a call') ||
        m.contains('already in call') ||
        m.contains('already active call') ||
        m.contains('already have an active call');
  }

  Future<CallResponseEntity?> _recoverActiveCallConflict({
    required CallRequestEntity request,
    required int targetUserId,
  }) async {
    try {
      final pendingCalls = await getPendingCallsUseCase.execute();
      final currentCallId = _currentCallId;

      final relatedCalls = pendingCalls.where((c) {
        if (c.callId <= 0) return false;
        if (c.callerId == targetUserId || c.targetUserId == targetUserId) {
          return true;
        }
        if (currentCallId != null &&
            currentCallId > 0 &&
            c.callId == currentCallId) {
          return true;
        }
        return false;
      }).toList();

      relatedCalls.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (relatedCalls.isEmpty) {
        AppLogger.warning(
          'CallBloc: Active call conflict detected but no related pending call found for target=$targetUserId',
        );
      }

      for (final call in relatedCalls) {
        try {
          await endCallUseCase.execute(call.callId);
        } catch (e) {
          AppLogger.warning(
            'CallBloc: Failed to clean related stale call ${call.callId}: $e',
          );
        }
      }

      return await sendCallRequestUseCase.execute(request);
    } catch (e) {
      AppLogger.error('CallBloc: Active call conflict recovery failed', e);
      return null;
    }
  }

  void _startOutgoingTimeout() {
    _outgoingTimeoutTimer?.cancel();
    _outgoingTimeoutTimer = Timer(_outgoingTimeout, () {
      if (!isClosed) {
        add(const CallOutgoingTimeoutReached());
      }
    });
  }

  void _cancelOutgoingTimeout() {
    _outgoingTimeoutTimer?.cancel();
    _outgoingTimeoutTimer = null;
  }

  void _startConnectingTimeout() {
    _connectingTimeoutTimer?.cancel();
    _connectingTimeoutTimer = Timer(_connectingTimeout, () {
      if (!isClosed) {
        add(const CallConnectingTimeoutReached());
      }
    });
  }

  void _cancelConnectingTimeout() {
    _connectingTimeoutTimer?.cancel();
    _connectingTimeoutTimer = null;
  }

  Future<void> _safeEndCurrentCall({
    int? remoteUserId,
    bool signalREnd = true,
  }) async {
    final callId = _currentCallId;
    if (callId != null && callId > 0) {
      try {
        await endCallUseCase.execute(callId);
      } catch (e) {
        AppLogger.warning('CallBloc: safe end failed for callId=$callId: $e');
      }
    }

    final effectiveRemoteUserId = remoteUserId ?? _remoteUserId;
    if (effectiveRemoteUserId != null && effectiveRemoteUserId > 0) {
      try {
        await _endPendingCallsFallback(
          remoteUserId: effectiveRemoteUserId,
          preferredCallId: callId,
        );
      } catch (e) {
        AppLogger.warning('CallBloc: safe end pending fallback failed: $e');
      }

      // Emniyet kemeri: REST ile call ended olsa bile, SignalR "in-call" state'i takılı kalabiliyor.
      // Bu yüzden aktifse "EndCall" de gönder.
      if (signalREnd) {
        try {
          await signalRService.endCall(effectiveRemoteUserId.toString());
        } catch (e) {
          AppLogger.warning('CallBloc: safe end SignalR EndCall failed: $e');
        }
      }

      // END CALLKIT
      if (_activeCallKitId != null) {
        await callKitIncomingService.endCall(_activeCallKitId!);
        _activeCallKitId = null;
      }
    }
  }

  Future<void> _endPendingCallsFallback({
    required int remoteUserId,
    int? preferredCallId,
  }) async {
    final pendingCalls = await getPendingCallsUseCase.execute();
    if (pendingCalls.isEmpty) return;

    final withValidId = pendingCalls.where((c) => c.callId > 0).toList();
    if (withValidId.isEmpty) return;

    final candidates = <CallResponseEntity>[];
    if (preferredCallId != null && preferredCallId > 0) {
      candidates.addAll(withValidId.where((c) => c.callId == preferredCallId));
    }
    if (candidates.isEmpty) {
      candidates.addAll(
        withValidId.where(
          (c) => c.callerId == remoteUserId || c.targetUserId == remoteUserId,
        ),
      );
    }

    if (candidates.isEmpty) {
      AppLogger.warning(
        'CallBloc: Pending fallback skipped. No related pending call found for remote=$remoteUserId '
        'preferredCallId=${preferredCallId ?? 0}',
      );
      return;
    }

    for (final call in candidates) {
      try {
        await endCallUseCase.execute(call.callId);
        AppLogger.info(
          'CallBloc: Pending call force-ended. CallId=${call.callId}',
        );
      } catch (e) {
        AppLogger.warning(
          'CallBloc: Pending call force-end failed. CallId=${call.callId} Error=$e',
        );
      }
    }
  }

  Future<void> _cleanupCall() async {
    final ongoing = _cleanupFuture;
    if (ongoing != null) {
      await ongoing;
      return;
    }

    final cleanupTask = _performCleanupCall();
    _cleanupFuture = cleanupTask;
    try {
      await cleanupTask;
    } finally {
      _cleanupFuture = null;
      _isLocalHangupInProgress = false;
    }
  }

  Future<void> _performCleanupCall() async {
    _cancelOutgoingTimeout();
    _cancelConnectingTimeout();

    _callTimer?.cancel();
    _callTimer = null;
    _callDuration = Duration.zero;

    _remoteUserId = null;
    _currentCallId = null;
    _resetSignalingSessionState();

    await _connectionStateSub?.cancel();
    _connectionStateSub = null;

    await _iceCandidateSub?.cancel();
    _iceCandidateSub = null;

    if (_activeCallKitId != null) {
      try {
        await callKitIncomingService.endCall(_activeCallKitId!);
      } catch (_) {}
      _activeCallKitId = null;
    }

    await webRTCService.dispose();
  }

  void _startCallTimer() {
    _callDuration = Duration.zero;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const CallDurationTicked());
    });
  }

  String _rtcStateToString(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        return 'connected';
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        return 'failed';
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        return 'disconnected';
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        return 'closed';
      case RTCPeerConnectionState.RTCPeerConnectionStateNew:
        return 'new';
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        return 'connecting';
    }
  }

  @override
  Future<void> close() async {
    final callId = _currentCallId;
    if (callId != null && callId > 0) {
      try {
        await endCallUseCase.execute(callId);
      } catch (e) {
        AppLogger.warning('CallBloc: Auto end on close failed: $e');
      }
    }

    try {
      await _signalingQueue;
    } catch (_) {
      // Queue errors are already logged where they occur.
    }

    await _cleanupCall();

    await _incomingCallSub?.cancel();
    await _callAcceptedSub?.cancel();
    await _callRejectedSub?.cancel();
    await _callEndedSub?.cancel();
    await _offerSub?.cancel();
    await _answerSub?.cancel();
    await _iceCandidateSignalRSub?.cancel();
    await _callRequestFailedSub?.cancel();
    await _callActionFailedSub?.cancel();
    await _signalDeliveryFailedSub?.cancel();

    return super.close();
  }
}
