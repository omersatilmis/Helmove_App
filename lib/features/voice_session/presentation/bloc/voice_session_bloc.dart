import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../domain/enums/rtc_state.dart';
import '../../domain/entities/voice_session_entity.dart';
import '../../domain/entities/voice_session_participant_entity.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_voice_session_usecase.dart';
import '../../domain/usecases/join_voice_session_usecase.dart';
import '../../domain/usecases/leave_voice_session_usecase.dart';
import '../../domain/usecases/invite_to_voice_session_usecase.dart';
import '../../domain/usecases/get_voice_session_details_usecase.dart';
import '../../domain/usecases/get_my_voice_sessions_usecase.dart';
import '../../../auth/domain/usecases/get_current_user_id_use_case.dart';
import '../../domain/usecases/accept_voice_session_invitation_usecase.dart';
import '../../../../core/services/callkit_incoming_service.dart';
import '../../../../core/services/communication_realtime_bus.dart';
import '../../../../core/services/communication_refresh_coordinator.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/app_session.dart';
import '../../../../core/services/permissions_service.dart';
import '../../../../core/services/audio_orchestrator_service.dart';
import '../../../../core/services/app_background_service.dart';
import '../../../intercom/domain/intercom_engine.dart';
import '../../../intercom/domain/intercom_models.dart';
import '../../../intercom/domain/intercom_failure.dart';
import 'voice_session_event.dart';
import 'voice_session_state.dart';

import '../../domain/usecases/reject_voice_session_invitation_usecase.dart';
import '../../domain/usecases/end_voice_session_usecase.dart';
import '../../domain/usecases/kick_user_usecase.dart';
import '../../domain/usecases/mute_user_usecase.dart';
import '../../domain/usecases/transfer_host_usecase.dart';
import '../../domain/usecases/promote_participant_usecase.dart';
import '../../domain/usecases/demote_participant_usecase.dart';
import '../../domain/usecases/kick_participant_usecase.dart';

class VoiceSessionBloc extends Bloc<VoiceSessionEvent, VoiceSessionState> {
  final CreateVoiceSessionUseCase createVoiceSessionUseCase;
  final JoinVoiceSessionUseCase joinVoiceSessionUseCase;
  final LeaveVoiceSessionUseCase leaveVoiceSessionUseCase;
  final InviteToVoiceSessionUseCase inviteToVoiceSessionUseCase;
  final GetVoiceSessionDetailsUseCase getVoiceSessionDetailsUseCase;
  final GetMyVoiceSessionsUseCase getMyVoiceSessionsUseCase;
  final GetCurrentUserIdUseCase getCurrentUserIdUseCase;
  final AcceptVoiceSessionInvitationUseCase acceptVoiceSessionInvitationUseCase;
  final RejectVoiceSessionInvitationUseCase rejectVoiceSessionInvitationUseCase;
  final EndVoiceSessionUseCase endVoiceSessionUseCase;
  final AppSession appSession;
  final SignalRService signalRService;
  final CommunicationRealtimeBus realtimeBus;
  final CommunicationRefreshCoordinator refreshCoordinator;
  final CallKitIncomingService callKitIncomingService;
  final KickUserUseCase kickUserUseCase;
  final MuteUserUseCase muteUserUseCase;
  final TransferHostUseCase transferHostUseCase;
  final PermissionsService permissionsService;
  final IntercomEngine intercomEngine;
  final AudioOrchestratorService audioOrchestratorService;
  final PromoteParticipantUseCase promoteParticipantUseCase;
  final DemoteParticipantUseCase demoteParticipantUseCase;
  final KickParticipantUseCase kickParticipantUseCase;

  String? _activeCallKitId;

  StreamSubscription? _realtimeSubscription;
  StreamSubscription? _refreshSubscription;
  StreamSubscription? _appSessionUserIdSubscription;
  StreamSubscription? _errorSubscription;

  StreamSubscription? _intercomStateSubscription;
  Timer? _syncTimer;

  bool _isJoinInFlight = false; // [NEW] Prevent duplicate joins
  bool _isLeaveInFlight = false;
  int? _leaveInFlightSessionId;
  bool _notFoundLocked = false;
  static const Duration _voiceDetailsForwardThrottle = Duration(
    milliseconds: 450,
  );
  final Map<int, DateTime> _lastVoiceDetailsForwardAt = <int, DateTime>{};

  // Version Conflict Resolution: Session version tracking
  final Map<int, int> _lastSessionVersions = <int, int>{};

  VoiceSessionBloc({
    required this.createVoiceSessionUseCase,
    required this.joinVoiceSessionUseCase,
    required this.leaveVoiceSessionUseCase,
    required this.inviteToVoiceSessionUseCase,
    required this.getVoiceSessionDetailsUseCase,
    required this.getMyVoiceSessionsUseCase,
    required this.getCurrentUserIdUseCase,
    required this.acceptVoiceSessionInvitationUseCase,
    required this.rejectVoiceSessionInvitationUseCase,
    required this.endVoiceSessionUseCase,
    required this.appSession,
    required this.signalRService,
    required this.realtimeBus,
    required this.refreshCoordinator,
    required this.callKitIncomingService,
    required this.kickUserUseCase,
    required this.muteUserUseCase,
    required this.transferHostUseCase,
    required this.permissionsService,
    required this.intercomEngine,
    required this.audioOrchestratorService,
    required this.promoteParticipantUseCase,
    required this.demoteParticipantUseCase,
    required this.kickParticipantUseCase,
  }) : super(const VoiceSessionState()) {
    _realtimeSubscription = realtimeBus.events.listen((event) {
      if (isClosed) return;
      if (_notFoundLocked) return;

      if (event is RideTerminatedRealtimeEvent) {
        add(RideTerminatedVoiceSessionEvent(event.rideId.toString()));
        return;
      }

      if (event is RideCreatedRealtimeEvent) {
        refreshCoordinator.requestVoiceSessionsRefresh(
          reason: 'rt_ride_created',
        );
        return;
      }

      if (event is GroupRideUpdatedRealtimeEvent) {
        final activeSessionId = state.session?.id;
        if (activeSessionId != null) {
          refreshCoordinator.requestVoiceSessionDetailsRefresh(
            activeSessionId,
            reason: 'rt_ride_updated',
          );
        } else {
          refreshCoordinator.requestVoiceSessionsRefresh(
            reason: 'rt_ride_updated',
          );
        }
        return;
      }

      if (event is UserJoinedVoiceSessionRealtimeEvent) {
        add(
          VoiceSessionMembershipDeltaEvent(
            sessionId: event.sessionId,
            userId: event.userId,
            nextStatus: 'Joined',
            version: event.version,
          ),
        );
        return;
      }

      if (event is UserLeftVoiceSessionRealtimeEvent) {
        // [NEW] Optimize API calls: Ignore echo of our own leave event
        if (event.userId == state.currentUserId?.toString()) {
          // Kendimiz için UserLeft geldiyse ve UI henüz bizi çıkarmadıysa
          // (Race condition: state.session henüz yüklenmemiş olsa bile temizle!)
          if (state.status != VoiceSessionStatus.left) {
            add(
              VoiceSessionForceRemovedEvent(
                event.sessionId,
                reason: 'Oturumdan ayrıldınız',
              ),
            );
          }
          return;
        }

        add(
          VoiceSessionMembershipDeltaEvent(
            sessionId: event.sessionId,
            userId: event.userId,
            nextStatus: 'Left',
            version: event.version,
          ),
        );
        return;
      }

      if (event is UserDisconnectedVoiceSessionRealtimeEvent) {
        add(
          VoiceSessionMembershipDeltaEvent(
            sessionId: event.sessionId,
            userId: event.userId,
            nextStatus: 'Disconnected',
            version: event.version,
          ),
        );
        return;
      }

      if (event is HostChangedRealtimeEvent) {
        add(VoiceSessionHostChanged(event.data));
        return;
      }

      if (event is VoiceSessionRefreshRealtimeEvent) {
        // Smart Refresh Priority: reason'a göre aksiyon al
        final reason = event.reason ?? 'unknown';
        final needsFullRefresh = _shouldTriggerFullRefresh(reason);

        if (state.session?.id == event.sessionId && event.sessionId > 0) {
          if (needsFullRefresh) {
            refreshCoordinator.requestVoiceSessionDetailsRefresh(
              event.sessionId,
              reason: 'rt_voice_refresh:$reason',
            );
          }
          // Membership changes (user_joined, user_left, user_disconnected)
          // already handled by delta events, no full refresh needed
        } else {
          refreshCoordinator.requestVoiceSessionsRefresh(
            reason: 'rt_voice_refresh:$reason',
          );
        }
        return;
      }

      if (event is UserForceRemovedRealtimeEvent) {
        add(VoiceSessionForceRemovedEvent(event.sessionId));
        return;
      }

      if (event is ParticipantStatusUpdatedRealtimeEvent) {
        add(ParticipantStatusUpdatedEvent(event.payload));
        return;
      }

      if (event is UserMuteStateChangedRealtimeEvent) {
        add(UserMuteStateChangedEvent(event.payload));
      }
    });

    _refreshSubscription = refreshCoordinator.requests.listen((request) {
      if (isClosed) return;
      if (_notFoundLocked) return;

      if (request.target == CommunicationRefreshTarget.voiceSessions) {
        add(GetMyVoiceSessionsEvent(force: request.force));
        return;
      }

      if (request.target == CommunicationRefreshTarget.voiceSessionDetails) {
        final sessionId = request.sessionId;
        if (sessionId != null && sessionId > 0) {
          if (!request.force && _shouldThrottleVoiceDetailsForward(sessionId)) {
            return;
          }
          add(GetVoiceSessionDetailsEvent(sessionId, force: request.force));
        }
        return;
      }

      if (request.target == CommunicationRefreshTarget.reconnectInvalidation) {
        add(const GetMyVoiceSessionsEvent(force: true));
        final activeSessionId = state.session?.id;
        if (activeSessionId != null) {
          add(GetVoiceSessionDetailsEvent(activeSessionId, force: true));
        }
      }
    });

    _errorSubscription = refreshCoordinator.errors.listen((event) {
      if (isClosed) return;
      if (event.category != RealtimeErrorCategory.notFound) return;
      if (event.source != RealtimeStateCoordinator.sourceVoiceSession) return;
      add(VoiceSessionNotFoundDetectedEvent(event.message));
    });

    _appSessionUserIdSubscription = appSession.currentUserIdStream
        .distinct()
        .listen((userId) {
          if (!isClosed) {
            add(AppSessionCurrentUserChangedEvent(userId));
          }
        });

    _intercomStateSubscription = intercomEngine.state$.listen((intercomState) {
      if (!isClosed) {
        add(IntercomStateChangedEvent(intercomState));
      }
    });
    // SignalR init is managed centrally by CallListenerService/AuthProvider.`r`n
    on<CreateVoiceSessionEvent>(_onCreateVoiceSession);
    on<JoinVoiceSessionEvent>(_onJoinVoiceSession);
    on<LeaveVoiceSessionEvent>(_onLeaveVoiceSession);
    on<EndVoiceSessionEvent>(_onEndVoiceSession);
    on<InviteUsersEvent>(_onInviteUsers);
    on<GetVoiceSessionDetailsEvent>(
      _onGetVoiceSessionDetails,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 200))
          .asyncExpand(mapper),
    );
    on<GetMyVoiceSessionsEvent>(
      _onGetMyVoiceSessions,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 500))
          .asyncExpand(mapper),
    );
    on<AcceptVoiceSessionInviteEvent>(_onAcceptVoiceSessionInvite);
    on<RejectVoiceSessionInviteEvent>(_onRejectVoiceSessionInvite);

    // New Handlers
    on<KickUserEvent>(_onKickUser);
    on<MuteUserEvent>(_onMuteUser);

    on<TransferHostEvent>(_onTransferHost);
    on<PromoteParticipantEvent>(_onPromoteParticipant);
    on<DemoteParticipantEvent>(_onDemoteParticipant);
    on<KickParticipantEvent>(_onKickParticipant);
    on<VoiceSessionHostChanged>(_onHostChanged);

    on<ConnectToLiveKitEvent>(_onConnectToLiveKit);
    on<DisconnectFromLiveKitEvent>(_onDisconnectFromLiveKit);
    on<ToggleMicrophoneEvent>(_onToggleMicrophone);
    on<IntercomStateChangedEvent>(
      _onIntercomStateChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .asyncExpand(mapper),
    );
    on<AppSessionCurrentUserChangedEvent>(_onAppSessionCurrentUserChanged);
    on<ParticipantStatusUpdatedEvent>(_onParticipantStatusUpdated);
    on<UserMuteStateChangedEvent>(_onUserMuteStateChanged);
    on<ClearSessionDataEvent>(_onClearSessionData);
    on<VoiceSessionNotFoundDetectedEvent>(_onVoiceSessionNotFoundDetected);

    on<VoiceSessionForceRemovedEvent>(_onVoiceSessionForceRemoved);
    on<RideTerminatedVoiceSessionEvent>(_onRideTerminatedVoiceSession);
    on<VoiceSessionMembershipDeltaEvent>(_onVoiceSessionMembershipDelta);
    on<TeardownVoiceSessionLocalEvent>(_onTeardownVoiceSessionLocal);
  }

  bool _shouldThrottleVoiceDetailsForward(int sessionId) {
    final now = DateTime.now();
    final last = _lastVoiceDetailsForwardAt[sessionId];
    if (last != null && now.difference(last) < _voiceDetailsForwardThrottle) {
      debugPrint(
        '[Realtime-F2][VoiceSessionBloc] Throttled details refresh for session $sessionId',
      );
      return true;
    }
    _lastVoiceDetailsForwardAt[sessionId] = now;
    return false;
  }

  void _onVoiceSessionMembershipDelta(
    VoiceSessionMembershipDeltaEvent event,
    Emitter<VoiceSessionState> emit,
  ) {
    final patched = _applyMembershipPatch(
      sessionId: event.sessionId,
      userId: event.userId,
      nextStatus: event.nextStatus,
      version: event.version,
      emit: emit,
    );
    if (!patched) {
      refreshCoordinator.requestVoiceSessionsRefresh(
        reason: 'rt_membership_patch_miss',
      );
      if (state.session?.id == event.sessionId) {
        refreshCoordinator.requestVoiceSessionDetailsRefresh(
          event.sessionId,
          reason: 'rt_membership_patch_miss',
        );
      }
    }
  }

  /// Determines whether a status counts as "in the room" for joinedCount.
  bool _isActiveStatus(String status) {
    return status == 'Joined' ||
        status == 'Accepted' ||
        status == 'Disconnected';
  }

  bool _applyMembershipPatch({
    required int sessionId,
    required String userId,
    required String nextStatus,
    required int? version,
    required Emitter<VoiceSessionState> emit,
  }) {
    final eventVersionLabel = version?.toString() ?? '-';
    final parsedUserId = int.tryParse(userId);
    if (parsedUserId == null) {
      debugPrint('[Realtime-F2][Bloc] Skipping patch: invalid userId=$userId');
      return false;
    }

    // ── Version Conflict Resolution ──
    if (version != null) {
      final lastVersion = _lastSessionVersions[sessionId];

      if (lastVersion != null) {
        // Eski event geldi → skip
        if (version < lastVersion) {
          debugPrint(
            '[Realtime-F2][Bloc] Skipping old event: '
            'session=$sessionId version=$version < lastVersion=$lastVersion',
          );
          return false;
        }

        // Version gap detected → force refresh
        if (version > lastVersion + 1) {
          debugPrint(
            '[Realtime-F2][Bloc] Version gap detected: '
            'session=$sessionId lastVersion=$lastVersion → newVersion=$version. '
            'Triggering force refresh.',
          );
          add(GetVoiceSessionDetailsEvent(sessionId, force: true));
          _lastSessionVersions[sessionId] = version;
          return false; // Patch skip, refresh yapacak
        }
      }

      // Version güncelle
      _lastSessionVersions[sessionId] = version;
    }

    var changed = false;

    // ── 1. state.session (Aktif oturum detayı) Yamala ──
    VoiceSessionEntity? patchedCurrentSession = state.session;
    final currentSession = state.session;
    if (currentSession != null && currentSession.id == sessionId) {
      final patchedParticipants = List<VoiceSessionParticipantEntity>.from(
        currentSession.participants,
      );

      var participantStatusChanged = false;

      final participantIndex = patchedParticipants.indexWhere(
        (p) => p.userId == parsedUserId,
      );

      if (participantIndex != -1) {
        final participant = patchedParticipants[participantIndex];
        // İdempotent Guard: Zaten hedef statüdeyse atla (duplicate event)
        if (participant.status == nextStatus) {
          debugPrint(
            '[Realtime-F2][Bloc] Duplicate patch skipped: '
            'user=$userId already $nextStatus in session=$sessionId v$eventVersionLabel',
          );
        } else {
          patchedParticipants[participantIndex] = participant.copyWith(
            status: nextStatus,
          );
          participantStatusChanged = true;
          changed = true;
        }
      } else if (nextStatus == 'Joined') {
        // Katılımcı listede yok ama join event geldi → placeholder ekle
        patchedParticipants.add(
          VoiceSessionParticipantEntity(userId: parsedUserId, status: 'Joined'),
        );
        participantStatusChanged = true;
        changed = true;
        debugPrint(
          '[Realtime-F2][Bloc] Added missing participant $userId to session=$sessionId',
        );
      }

      // joinedCount'u sadece gerçek bir statü değişikliği olduğunda güncelle
      var nextJoinedCount = currentSession.joinedCount;
      if (participantStatusChanged && participantIndex != -1) {
        final oldStatus = currentSession.participants[participantIndex].status;
        final wasActive = _isActiveStatus(oldStatus);
        final isActive = _isActiveStatus(nextStatus);
        if (wasActive && !isActive) {
          nextJoinedCount = nextJoinedCount > 0 ? nextJoinedCount - 1 : 0;
        } else if (!wasActive && isActive) {
          nextJoinedCount += 1;
        }
        // Disconnected → Disconnected veya Joined → Joined gibi durumlarda count değişmez
      } else if (participantStatusChanged) {
        // Yeni eklenen katılımcı (placeholder)
        if (_isActiveStatus(nextStatus)) {
          nextJoinedCount += 1;
        }
      }

      patchedCurrentSession = currentSession.copyWith(
        participants: patchedParticipants,
        joinedCount: nextJoinedCount,
      );
      if (participantStatusChanged) {
        changed = true;
      }
    }

    // ── 2. mySessions listesi yamalama ──
    List<VoiceSessionEntity>? patchedMySessions;
    final mySessions = state.mySessions;
    if (mySessions != null) {
      patchedMySessions = mySessions.map((session) {
        if (session.id != sessionId) return session;

        // mySessions'taki katılımcı statüsünü de kontrol et (idempotent)

        final existingParticipant = session.participants
            .where((p) => p.userId == parsedUserId)
            .firstOrNull;

        if (existingParticipant != null &&
            existingParticipant.status == nextStatus) {
          // Zaten hedef statüde → joinedCount değişmesin
          return session;
        }

        changed = true;
        var nextJoinedCount = session.joinedCount;
        final oldStatus = existingParticipant?.status ?? '';
        final wasActive = _isActiveStatus(oldStatus);
        final isActive = _isActiveStatus(nextStatus);
        if (wasActive && !isActive) {
          nextJoinedCount = nextJoinedCount > 0 ? nextJoinedCount - 1 : 0;
        } else if (!wasActive && isActive) {
          nextJoinedCount += 1;
        }
        return session.copyWith(joinedCount: nextJoinedCount);
      }).toList();
    }

    if (!changed) {
      return false;
    }

    emit(
      state.copyWith(
        session: patchedCurrentSession,
        mySessions: patchedMySessions ?? state.mySessions,
      ),
    );
    debugPrint(
      '[Realtime-F2][Bloc] Applying patch $nextStatus for user=$userId session=$sessionId v$eventVersionLabel',
    );
    return true;
  }

  Future<void> _onCreateVoiceSession(
    CreateVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      // Singleton Session Guard: Aktif bir oturumdayken yeni grup oluşturulamaz
      if (state.activeSession != null) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.error,
            message:
                'Zaten aktif bir sürüştesiniz. Yeni grup oluşturmak için önce mevcut sürüşten ayrılın.',
          ),
        );
        return;
      }

      // ── 1. Permission Check (platform channel - can throw) ──
      bool permissionsOk = false;
      try {
        permissionsOk = await permissionsService.ensureVoiceSessionPermissions(
          requestLocation: false,
        );
      } catch (permError) {
        debugPrint("🔴 [VoiceSessionBloc] Permission check threw: $permError");
        permissionsOk = false;
      }

      if (!permissionsOk) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: VoiceSessionStatus.error,
              message: 'Oturum için gerekli izinler verilmedi.',
            ),
          );
        }
        return;
      }

      if (isClosed) return;
      emit(state.copyWith(status: VoiceSessionStatus.loading));

      // ── 2. Backend Create API Call ──
      final result = await createVoiceSessionUseCase(event.request);

      // CRITICAL: Synchronous fold — no async closures
      int? createdSessionId;
      String? createError;

      result.fold(
        (failure) {
          createError = failure.message;
        },
        (sessionId) {
          createdSessionId = sessionId;
        },
      );

      if (isClosed) return;

      if (createdSessionId == null) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.error,
            message: createError ?? 'Grup oluşturulamadı.',
          ),
        );
        return;
      }

      final sessionId = createdSessionId!;

      // ── 3. SignalR Group Join (can throw - isolated) ──
      try {
        await signalRService.joinVoiceSessionGroup(sessionId.toString());
      } catch (signalRError) {
        debugPrint(
          "⚠️ [VoiceSessionBloc] SignalR joinGroup failed (non-fatal): $signalRError",
        );
      }

      if (isClosed) return;

      // ── 4. CallKit Start (platform channel - can throw) ──
      try {
        final uuid = callKitIncomingService.generateCallKitId();
        _activeCallKitId = uuid;
        await callKitIncomingService.startOutboundCall(
          uuid: uuid,
          handle: "Grup Sürüşü",
          nameCaller: event.request.roomName ?? "Grup Sürüşü",
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await callKitIncomingService.markConnected(uuid);
      } catch (callKitError) {
        debugPrint(
          "⚠️ [VoiceSessionBloc] CallKit failed (non-fatal): $callKitError",
        );
      }

      if (isClosed) return;

      // ── 5. Fetch Session Details ──
      VoiceSessionEntity? createdSession;
      try {
        final detailResult = await getVoiceSessionDetailsUseCase(sessionId);
        detailResult.fold((l) => null, (s) => createdSession = s);
      } catch (detailError) {
        debugPrint(
          "⚠️ [VoiceSessionBloc] Detail fetch failed (non-fatal): $detailError",
        );
      }

      if (isClosed) return;

      // ── 6. Emit final Created state ──
      emit(
        state.copyWith(
          status: VoiceSessionStatus.created,
          sessionId: sessionId,
          session: createdSession,
        ),
      );
      _startSyncTimer();
    } catch (e, stack) {
      debugPrint(
        "🔴 [VoiceSessionBloc] _onCreateVoiceSession CAUGHT:\n"
        "   Error: $e\n"
        "   Stack: $stack",
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.error,
            message: 'Grup oluşturulurken bir hata oluştu: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onJoinVoiceSession(
    JoinVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    if (_isJoinInFlight) {
      debugPrint(
        "⚠️ [VoiceSessionBloc] _onJoinVoiceSession skipped — already in flight",
      );
      return;
    }
    _isJoinInFlight = true;

    try {
      // ── 1. Permission Check (platform channel - can throw) ──
      bool permissionsOk = false;
      try {
        permissionsOk = await permissionsService.ensureVoiceSessionPermissions(
          requestLocation: false,
        );
      } catch (permError) {
        debugPrint("🔴 [VoiceSessionBloc] Permission check threw: $permError");
        // Treat permission exception as denial
        permissionsOk = false;
      }

      if (!permissionsOk) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: VoiceSessionStatus.error,
              message: 'Oturum için gerekli izinler verilmedi.',
            ),
          );
        }
        return;
      }

      if (isClosed) return;
      emit(state.copyWith(status: VoiceSessionStatus.loading));

      // ── 2. Backend Join API Call ──
      final result = await joinVoiceSessionUseCase(event.sessionId);

      // CRITICAL: Use synchronous fold — no async closures!
      // async closures inside fold can throw and escape the outer try-catch.
      bool joinSuccess = false;
      String? joinError;

      result.fold(
        (failure) {
          joinError = failure.message;
        },
        (_) {
          joinSuccess = true;
        },
      );

      if (isClosed) return;

      if (!joinSuccess) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.error,
            message: joinError ?? 'Odaya katılınamadı.',
          ),
        );
        return;
      }

      // ── 3. SignalR Group Join (can throw - isolated) ──
      try {
        await signalRService.joinVoiceSessionGroup(event.sessionId.toString());
      } catch (signalRError) {
        debugPrint(
          "⚠️ [VoiceSessionBloc] SignalR joinGroup failed (non-fatal): $signalRError",
        );
        // Not fatal — session was joined on backend, SignalR is supplementary
      }

      if (isClosed) return;

      // ── 4. CallKit Start (platform channel - can throw) ──
      try {
        final uuid = callKitIncomingService.generateCallKitId();
        _activeCallKitId = uuid;
        await callKitIncomingService.startOutboundCall(
          uuid: uuid,
          handle: "Grup Sürüşü",
          nameCaller: "Grup Sürüşü",
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await callKitIncomingService.markConnected(uuid);
      } catch (callKitError) {
        debugPrint(
          "⚠️ [VoiceSessionBloc] CallKit failed (non-fatal): $callKitError",
        );
        // Not fatal — session still works without CallKit UI
      }

      if (isClosed) return;

      // ── 5. Fetch Session Details to populate activeSession ──
      VoiceSessionEntity? joinedSession;
      try {
        final detailResult = await getVoiceSessionDetailsUseCase(
          event.sessionId,
        );
        detailResult.fold((l) => null, (s) => joinedSession = s);
      } catch (detailError) {
        debugPrint(
          "⚠️ [VoiceSessionBloc] Detail fetch failed (non-fatal): $detailError",
        );
      }

      if (isClosed) return;

      // ── 6. Emit final Joined state ──
      emit(
        state.copyWith(
          status: VoiceSessionStatus.joined,
          message: "Odaya başarıyla katılındı",
          sessionId: event.sessionId,
          session: joinedSession, // may be null, but at least we won't crash
        ),
      );
      _startSyncTimer();
    } catch (e, stack) {
      debugPrint(
        "🔴 [VoiceSessionBloc] _onJoinVoiceSession CAUGHT:\n"
        "   Error: $e\n"
        "   Stack: $stack",
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.error,
            message: 'Odaya katılırken bir hata oluştu: ${e.toString()}',
          ),
        );
      }
    } finally {
      _isJoinInFlight = false;
    }
  }

  Future<void> _onLeaveVoiceSession(
    LeaveVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    if (_isLeaveInFlight && _leaveInFlightSessionId == event.sessionId) {
      debugPrint(
        "⚠️ [VoiceSessionBloc] Duplicate leave ignored for session ${event.sessionId}",
      );
      return;
    }

    if (state.status == VoiceSessionStatus.left &&
        state.sessionId == event.sessionId) {
      return;
    }

    _isLeaveInFlight = true;
    _leaveInFlightSessionId = event.sessionId;

    try {
      // ── Optimistic UI: Anında UI'ı güncelle, spinner yok ──
      // mySessions'dan bu session'ı çıkar
      final optimisticMySessions = state.mySessions
          ?.where((s) => s.id != event.sessionId)
          .toList();

      emit(
        state.copyWith(
          status: VoiceSessionStatus.left,
          sessionId: event.sessionId,
          message: "Oturumdan ayrılınıyor...",
          activeSpeakers: [],
          isLiveKitConnected: false,
          isMicOn: false,
          session: null,
          mySessions: optimisticMySessions,
          activeSessionOverride: () => null, // activeSession'ı sıfırla
        ),
      );

      _stopSyncTimer();

      // ── Arka planda temizlik ve API çağrısı ──
      await _teardownLocalSession(
        sessionId: event.sessionId,
        leaveSignalRGroup: false,
      );

      final result = await leaveVoiceSessionUseCase(event.sessionId);

      await result.fold(
        (failure) async {
          debugPrint(
            "❌ [VoiceSessionBloc] Backend leave failed (UI already updated): ${failure.message}",
          );
          // UI zaten güncellendi, sadece SignalR temizliği yap
          await signalRService.leaveVoiceSessionGroup(
            event.sessionId.toString(),
          );
        },
        (_) async {
          await signalRService.leaveVoiceSessionGroup(
            event.sessionId.toString(),
          );
          // Başarılı — sessizce mesajı güncelle
          emit(state.copyWith(message: "Oturumdan başarıyla ayrıldınız"));
        },
      );
    } finally {
      _isLeaveInFlight = false;
      _leaveInFlightSessionId = null;
    }
  }

  Future<void> _onEndVoiceSession(
    EndVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final session = state.session?.id == event.sessionId
        ? state.session
        : state.mySessions?.where((s) => s.id == event.sessionId).firstOrNull;
    if (session == null) return;

    final currentUserId = state.currentUserId;
    final currentUserParticipant = session.participants
        .cast<VoiceSessionParticipantEntity?>()
        .firstWhere((p) => p?.userId == currentUserId, orElse: () => null);

    final isCaptainOrAdmin =
        currentUserParticipant?.role.name == 'Captain' ||
        currentUserParticipant?.role.name == 'Admin';

    if (!isCaptainOrAdmin) {
      add(LeaveVoiceSessionEvent(event.sessionId));
      return;
    }

    try {
      emit(state.copyWith(status: VoiceSessionStatus.loading));

      // 1. Teardown local session first (stop audio, etc.)
      await _teardownLocalSession(
        sessionId: event.sessionId,
        leaveSignalRGroup:
            false, // Will be handled by SignalR service call below
      );

      // 2. Call Backend to End Session
      final result = await endVoiceSessionUseCase(event.sessionId);

      await result.fold(
        (failure) async {
          // Force UI update even if backend fails
          emit(
            state.copyWith(
              status: VoiceSessionStatus.left,
              sessionId: event.sessionId,
              message: "Oturum sonlandırıldı (Hata: ${failure.message})",
              activeSpeakers: [],
              isLiveKitConnected: false,
              isMicOn: false,
              session: null,
            ),
          );
          _stopSyncTimer();
        },
        (_) async {
          // 3. Notify SignalR (End Group)
          await signalRService.leaveVoiceSessionGroup(
            event.sessionId.toString(),
          );

          // ── Optimistic UI: MySessions update ve activeSession temizliği ──
          final optimisticMySessions = state.mySessions
              ?.where((s) => s.id != event.sessionId)
              .toList();

          emit(
            state.copyWith(
              status: VoiceSessionStatus.ended,
              sessionId: event.sessionId,
              message: "Oturum başarıyla sonlandırıldı",
              activeSpeakers: [],
              isLiveKitConnected: false,
              isMicOn: false,
              session: null,
              mySessions: optimisticMySessions,
              activeSessionOverride: () => null,
            ),
          );
          _stopSyncTimer();
        },
      );
    } catch (e) {
      debugPrint("❌ [VoiceSessionBloc] End session error: $e");
      emit(
        state.copyWith(status: VoiceSessionStatus.error, message: e.toString()),
      );
    }
  }

  Future<void> _onInviteUsers(
    InviteUsersEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    // 1. Loading State (Optional, but good for UI feedback)
    emit(state.copyWith(status: VoiceSessionStatus.loading));

    final result = await inviteToVoiceSessionUseCase(
      event.sessionId,
      event.request,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: VoiceSessionStatus.inviteSent,
          message: "Davetler baÅŸarÄ±yla gÃ¶nderildi",
        ),
      ),
    );
  }

  Future<void> _onGetVoiceSessionDetails(
    GetVoiceSessionDetailsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      if (_notFoundLocked && !event.force) {
        return;
      }

      await _ensureCurrentUserId(emit);

      // Sadece ilk yüklemede loading gösterelim, refreshlerde mevcut data kalsın
      if (state.session == null) {
        emit(state.copyWith(status: VoiceSessionStatus.loading));
      }

      // ─── Race-Condition Retry ───────────────────────────────────────
      // Davet edilen kişi gruba katılınca hemen bu sayfa açılıyor,
      // ama backend join/invite işlemi henüz tamamlanmamış olabiliyor.
      // Retry ile IntercomEngine.attachSession'ın mutlaka çalışmasını
      // sağlıyoruz — yoksa P2P headless call yanıtsız kalır.
      const maxRetries = 3;
      for (var attempt = 0; attempt <= maxRetries; attempt++) {
        final result = await refreshCoordinator.runVoiceSessionDetails(
          event.sessionId,
          () => getVoiceSessionDetailsUseCase(event.sessionId),
          // First call uses in-flight dedup; retries bypass cache to ensure a real retry.
          force: event.force || attempt > 0,
          // Phase 5 scope: in-flight dedup only, no throttle cache yet.
          throttleWindow: Duration.zero,
        );
        final isSuccess = result.fold((_) => false, (_) => true);

        if (isSuccess) {
          await result.fold((_) async {}, (session) async {
            final activeParticipants = session.participants.where((p) {
              return p.status != 'Left' && p.status != 'Rejected';
            }).toList();

            final updatedSession = session.copyWith(
              participants: activeParticipants,
            );

            // mySessions listesindeki ilgili session'ı da güncelle
            // böylece activeSession (mySessions'dan türetilen) her zaman güncel kalır.
            final syncedMySessions = state.mySessions?.map((s) {
              return s.id == updatedSession.id ? updatedSession : s;
            }).toList();

            emit(
              state.copyWith(
                status: VoiceSessionStatus.detailsLoaded,
                session: updatedSession,
                mySessions: syncedMySessions,
              ),
            );

            final currentUserId =
                state.currentUserId ?? await _ensureCurrentUserId(emit);
            if (currentUserId != null) {
              final intercomParticipants = activeParticipants
                  .where(
                    (p) =>
                        p.status == 'Joined' ||
                        p.status == 'Accepted' ||
                        p.status == 'Disconnected' ||
                        p.status == 'Invited',
                  )
                  .map(
                    (p) => IntercomParticipant(
                      userId: p.userId,
                      displayName: '${p.firstName ?? ''} ${p.lastName ?? ''}'
                          .trim(),
                      isLocal: p.userId == currentUserId,
                      isSpeaking: state.activeSpeakers.contains(
                        p.userId.toString(),
                      ),
                    ),
                  )
                  .toList();

              final activeIds = intercomParticipants
                  .map((participant) => participant.userId)
                  .toList();

              // Only call attachSession on the first successful attempt
              // to prevent the re-initialization loop during retries.
              if (attempt == 0) {
                await intercomEngine.attachSession(
                  IntercomSessionContext(
                    sessionId: session.id,
                    roomName: session.roomName,
                    adminId: session.adminId, // Using adminId here!
                    localUserId: currentUserId,
                    activeParticipantUserIds: activeIds,
                    participants: intercomParticipants,
                  ),
                );
              }

              // [FIX] Admin CallKit: admin creates group ride which
              // implicitly creates a voice session server-side. They
              // never go through Create/JoinVoiceSessionEvent, so
              // CallKit was never started. Start it here if missing.
              if (_activeCallKitId == null) {
                try {
                  final uuid = callKitIncomingService.generateCallKitId();
                  _activeCallKitId = uuid;
                  await callKitIncomingService.startOutboundCall(
                    uuid: uuid,
                    handle: "Grup Sürüşü",
                    nameCaller: session.title,
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                  await callKitIncomingService.markConnected(uuid);
                } catch (e) {
                  // Ignore CallKit initialization errors to avoid crashing details fetch
                }
              }
            }
          });
          return; // Başarılı → çık
        }

        final maybeFailure = result.fold((failure) => failure, (_) => null);
        if (maybeFailure != null && _isNotFoundFailure(maybeFailure.message)) {
          refreshCoordinator.reportNotFound(
            message: 'Grup artık mevcut değil',
            source: RealtimeStateCoordinator.sourceVoiceSession,
            dedupKey: 'voice_session_404:${event.sessionId}',
          );
          return;
        }

        // Son deneme → hatayı göster
        if (attempt == maxRetries) {
          result.fold(
            (failure) => emit(
              state.copyWith(
                status: VoiceSessionStatus.error,
                message: failure.message,
              ),
            ),
            (_) {},
          );
          return;
        }

        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    } catch (e) {
      emit(
        state.copyWith(status: VoiceSessionStatus.error, message: e.toString()),
      );
    }
  }

  Future<void> _onGetMyVoiceSessions(
    GetMyVoiceSessionsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      if (_notFoundLocked && !event.force) {
        return;
      }

      await _ensureCurrentUserId(emit);

      final hasActiveSession = state.session != null;
      if (!hasActiveSession) {
        emit(state.copyWith(status: VoiceSessionStatus.loading));
      }

      final result = await refreshCoordinator.runVoiceSessions(
        () => getMyVoiceSessionsUseCase(),
        force: event.force,
        // 4s cooldown to reduce repeated list-fetch bursts.
        throttleWindow: const Duration(seconds: 4),
      );
      result.fold(
        (failure) {
          if (_isNotFoundFailure(failure.message)) {
            refreshCoordinator.reportNotFound(
              message: 'Grup artık mevcut değil',
              source: RealtimeStateCoordinator.sourceVoiceSession,
              dedupKey: 'voice_sessions_404',
            );
            return;
          }

          // Keep in-session UX stable: background list refresh errors should not
          // force the whole voice state into error while call is alive.
          if (hasActiveSession) {
            debugPrint(
              "⚠️ [VoiceSessionBloc] Non-blocking my-sessions refresh error: ${failure.message}",
            );
            return;
          }

          emit(
            state.copyWith(
              status: VoiceSessionStatus.error,
              message: failure.message,
            ),
          );
        },
        (sessions) {
          if (hasActiveSession) {
            emit(state.copyWith(mySessions: sessions));
            return;
          }

          emit(
            state.copyWith(
              status: VoiceSessionStatus.mySessionsLoaded,
              mySessions: sessions,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(status: VoiceSessionStatus.error, message: e.toString()),
      );
    }
  }

  Future<int?> _ensureCurrentUserId(Emitter<VoiceSessionState> emit) async {
    if (state.currentUserId != null) {
      return state.currentUserId;
    }

    final userId = await getCurrentUserIdUseCase();
    if (userId != null && !isClosed) {
      emit(state.copyWith(currentUserId: userId));
    }
    return userId;
  }

  Future<void> _onAcceptVoiceSessionInvite(
    AcceptVoiceSessionInviteEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      // Singleton Session Guard: Aktif bir oturumdayken yeni davet kabul edilemez
      if (state.activeSession != null) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.error,
            message:
                'Zaten aktif bir sürüştesiniz. Daveti kabul etmek için önce mevcut sürüşten ayrılın.',
          ),
        );
        return;
      }

      // ── Optimistic UI: Snapshot al, hemen güncelle ──
      final snapshot = state;
      final currentUserId = state.currentUserId;

      // mySessions'taki davetin statüsünü hemen 'Accepted' yap
      final optimisticMySessions = state.mySessions?.map((s) {
        if (s.id != event.sessionId) return s;
        if (currentUserId == null) return s;
        final updatedParticipants = s.participants.map((p) {
          if (p.userId == currentUserId && p.status == 'Invited') {
            return p.copyWith(status: 'Accepted');
          }
          return p;
        }).toList();
        return s.copyWith(participants: updatedParticipants);
      }).toList();

      // Aynı güncellemeyi state.session (detailedSession) üzerinde de yap
      VoiceSessionEntity? optimisticSession = state.session;
      if (optimisticSession != null &&
          optimisticSession.id == event.sessionId &&
          currentUserId != null) {
        final updatedParticipants = optimisticSession.participants.map((p) {
          if (p.userId == currentUserId && p.status == 'Invited') {
            return p.copyWith(status: 'Accepted');
          }
          return p;
        }).toList();
        optimisticSession = optimisticSession.copyWith(
          participants: updatedParticipants,
        );
      }

      emit(
        state.copyWith(
          status: VoiceSessionStatus.inviteAccepted,
          sessionId: event.sessionId,
          mySessions: optimisticMySessions,
          session: optimisticSession,
        ),
      );

      // ── Arka planda API çağrısı ──
      final result = await acceptVoiceSessionInvitationUseCase(event.sessionId);

      // fold içindeki exception'ları da yakalıyoruz
      bool apiSuccess = false;
      String? apiError;

      result.fold(
        (failure) {
          apiError = failure.message;
        },
        (_) {
          apiSuccess = true;
        },
      );

      if (isClosed) return;

      if (!apiSuccess) {
        // ── Rollback: API başarısız → eski state'e dön ──
        debugPrint(
          "❌ [VoiceSessionBloc] Accept API failed, rolling back: $apiError",
        );
        emit(
          snapshot.copyWith(
            status: VoiceSessionStatus.error,
            message: apiError ?? 'Davet kabul edilemedi.',
          ),
        );
        return;
      }

      // Başarılı — devamında gerekli event zincirini tetikle
      if (!isClosed) {
        add(const GetMyVoiceSessionsEvent(force: true));
        add(JoinVoiceSessionEvent(event.sessionId));
        add(GetVoiceSessionDetailsEvent(event.sessionId, force: true));
        _startSyncTimer();
      }
    } catch (e, stack) {
      debugPrint(
        "🔴 [VoiceSessionBloc] _onAcceptVoiceSessionInvite CAUGHT:\n"
        "   Error: $e\n"
        "   Stack: $stack",
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.error,
            message: 'Davet kabul edilirken bir hata oluştu: ${e.toString()}',
          ),
        );
      }
    }
  }

  Future<void> _onRejectVoiceSessionInvite(
    RejectVoiceSessionInviteEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      // ── Optimistic UI: Snapshot al, hemen güncelle ──
      final snapshot = state;

      // mySessions'taki davetin statüsünü hemen 'Rejected' yap
      final optimisticMySessions = state.mySessions?.map((session) {
        if (session.id != event.sessionId) return session;
        final currentUserId = state.currentUserId;
        if (currentUserId == null) return session;
        final updatedParticipants = session.participants.map((p) {
          if (p.userId == currentUserId && p.status == 'Invited') {
            return p.copyWith(status: 'Rejected');
          }
          return p;
        }).toList();
        return session.copyWith(participants: updatedParticipants);
      }).toList();

      emit(state.copyWith(mySessions: optimisticMySessions));

      // ── Arka planda API çağrısı ──
      final result = await rejectVoiceSessionInvitationUseCase(event.sessionId);
      await result.fold(
        (failure) async {
          // ── Rollback: API başarısız → eski state'e dön ──
          debugPrint(
            "❌ [VoiceSessionBloc] Reject API failed, rolling back: ${failure.message}",
          );
          emit(
            snapshot.copyWith(
              status: VoiceSessionStatus.error,
              message: failure.message,
            ),
          );
        },
        (_) async {
          // Başarılı
          add(const GetMyVoiceSessionsEvent(force: true));
        },
      );
    } catch (e) {
      emit(
        state.copyWith(status: VoiceSessionStatus.error, message: e.toString()),
      );
    }
  }

  Future<void> _onKickUser(
    KickUserEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await kickUserUseCase(event.sessionId, event.targetUserId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: "KullanÄ±cÄ± atÄ±lamadÄ±: ${failure.message}",
        ),
      ),
      (_) {
        add(GetVoiceSessionDetailsEvent(event.sessionId));
        emit(
          state.copyWith(message: "KullanÄ±cÄ± atÄ±ldÄ±"),
        ); // Transient message
      },
    );
  }

  Future<void> _onMuteUser(
    MuteUserEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await muteUserUseCase(event.sessionId, event.targetUserId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: "KullanÄ±cÄ± susturulamadÄ±: ${failure.message}",
        ),
      ),
      (_) => emit(state.copyWith(message: "KullanÄ±cÄ± susturuldu")),
    );
  }

  Future<void> _onTransferHost(
    TransferHostEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await transferHostUseCase(event.sessionId, event.newHostId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: "Captain devredilemedi: ${failure.message}",
        ),
      ),
      (_) {
        add(GetVoiceSessionDetailsEvent(event.sessionId));
        emit(state.copyWith(message: "Captain yetkisi devredildi"));
      },
    );
  }

  Future<void> _onPromoteParticipant(
    PromoteParticipantEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await promoteParticipantUseCase(
      event.sessionId,
      event.targetUserId,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: "RÃ¼tbe yÃ¼kseltilemedi: ${failure.message}",
        ),
      ),
      (_) {
        if (state.session != null) {
          add(GetVoiceSessionDetailsEvent(state.session!.id));
        }
        emit(state.copyWith(message: "KullanÄ±cÄ± rÃ¼tbesi yÃ¼kseltildi"));
      },
    );
  }

  Future<void> _onDemoteParticipant(
    DemoteParticipantEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await demoteParticipantUseCase(
      event.sessionId,
      event.targetUserId,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: "RÃ¼tbe dÃ¼ÅŸÃ¼rÃ¼lemedi: ${failure.message}",
        ),
      ),
      (_) {
        if (state.session != null) {
          add(GetVoiceSessionDetailsEvent(state.session!.id));
        }
        emit(state.copyWith(message: "KullanÄ±cÄ± rÃ¼tbesi dÃ¼ÅŸÃ¼rÃ¼ldÃ¼"));
      },
    );
  }

  Future<void> _onKickParticipant(
    KickParticipantEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await kickParticipantUseCase(
      event.rideId,
      event.targetUserId,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: "KullanÄ±cÄ± gruptan atÄ±lamadÄ±: ${failure.message}",
        ),
      ),
      (_) {
        if (state.session != null) {
          add(GetVoiceSessionDetailsEvent(state.session!.id));
        }
        emit(state.copyWith(message: "KullanÄ±cÄ± gruptan atÄ±ldÄ±"));
      },
    );
  }

  Future<void> _onHostChanged(
    VoiceSessionHostChanged event,
    Emitter<VoiceSessionState> emit,
  ) async {
    if (state.status == VoiceSessionStatus.detailsLoaded &&
        state.session != null) {
      final currentSessionId = state.session!.id;
      add(GetVoiceSessionDetailsEvent(currentSessionId));
    }
  }

  void _onParticipantStatusUpdated(
    ParticipantStatusUpdatedEvent event,
    Emitter<VoiceSessionState> emit,
  ) {
    if (state.session == null) return;

    final currentParticipants = state.session!.participants;
    final index = currentParticipants.indexWhere(
      (p) => p.userId == event.payload.userId,
    );

    if (index != -1) {
      final participant = currentParticipants[index];
      final updatedParticipant = VoiceSessionParticipantEntity(
        userId: participant.userId,
        username: participant.username,
        firstName: participant.firstName,
        lastName: participant.lastName,
        profileImage: participant.profileImage,
        status: participant.status,
        joinedAt: participant.joinedAt,
        phoneBatteryLevel:
            event.payload.phoneBatteryLevel ?? participant.phoneBatteryLevel,
        intercomBatteryLevel:
            event.payload.intercomBatteryLevel ??
            participant.intercomBatteryLevel,
        signalStrength:
            event.payload.signalStrength ?? participant.signalStrength,
        isRemoteMuted: event.payload.isRemoteMuted ?? participant.isRemoteMuted,
      );

      final updatedParticipants = List<VoiceSessionParticipantEntity>.from(
        currentParticipants,
      );
      updatedParticipants[index] = updatedParticipant;

      final updatedSession = state.session!.copyWith(
        participants: updatedParticipants,
      );

      emit(state.copyWith(session: updatedSession));

      // EÄŸer lokal kullanÄ±cÄ± ise IntercomEngine'i gÃ¼ncelle
      if (participant.userId == state.currentUserId &&
          event.payload.isRemoteMuted != null) {
        if (event.payload.isRemoteMuted!) {
          intercomEngine.setMicEnabled(false);
        }
      }
    }
  }

  Future<void> _onUserMuteStateChanged(
    UserMuteStateChangedEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    if (state.session == null) return;

    final currentParticipants = state.session!.participants;
    final index = currentParticipants.indexWhere(
      (p) => p.userId == event.payload.targetUserId,
    );

    if (index != -1) {
      final participant = currentParticipants[index];
      final updatedParticipant = participant.copyWith(
        isRemoteMuted: event.payload.isMuted,
      );

      final updatedParticipants = List<VoiceSessionParticipantEntity>.from(
        currentParticipants,
      );
      updatedParticipants[index] = updatedParticipant;

      final updatedSession = state.session!.copyWith(
        participants: updatedParticipants,
      );

      emit(state.copyWith(session: updatedSession));

      // EÄŸer lokal kullanÄ±cÄ± ise IntercomEngine'i gÃ¼ncelle
      if (participant.userId == state.currentUserId) {
        if (event.payload.isMuted) {
          intercomEngine.setMicEnabled(false);
        }
      }
    }
  }

  Future<void> _onVoiceSessionForceRemoved(
    VoiceSessionForceRemovedEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final currentSessionId = state.session?.id;

    if (currentSessionId != event.sessionId) {
      refreshCoordinator.requestVoiceSessionsRefresh(
        reason: 'voice_force_removed',
      );
      return;
    }

    await _teardownLocalSession(sessionId: event.sessionId);

    final optimisticMySessions = state.mySessions
        ?.where((s) => s.id != event.sessionId)
        .toList();

    emit(
      state.copyWith(
        status: VoiceSessionStatus.left,
        sessionId: event.sessionId,
        message: event.reason ?? 'Oturumdan çıkarıldınız',
        activeSpeakers: const [],
        isLiveKitConnected: false,
        isMicOn: false,
        session: null,
        mySessions: optimisticMySessions,
        activeSessionOverride: () => null,
        participantQualities: const {},
        rtcStatus: RtcConnectionStatus.disconnected,
      ),
    );

    refreshCoordinator.requestVoiceSessionsRefresh(
      reason: 'voice_force_removed',
    );
  }

  Future<void> _onRideTerminatedVoiceSession(
    RideTerminatedVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final activeSession = state.session;
    if (activeSession == null) {
      return;
    }

    final terminatedRideId = int.tryParse(event.rideId ?? '');
    final activeRideId = activeSession.rideId;

    if (terminatedRideId == null ||
        activeRideId == null ||
        activeRideId != terminatedRideId) {
      return;
    }

    await _teardownLocalSession(sessionId: activeSession.id);

    final optimisticMySessions = state.mySessions
        ?.where((s) => s.id != activeSession.id)
        .toList();

    emit(
      state.copyWith(
        status: VoiceSessionStatus.left,
        sessionId: activeSession.id,
        message: 'Grup sürüşü sonlandırıldı. Oturum kapatıldı.',
        activeSpeakers: const [],
        isLiveKitConnected: false,
        isMicOn: false,
        session: null,
        mySessions: optimisticMySessions,
        activeSessionOverride: () => null,
        participantQualities: const {},
        rtcStatus: RtcConnectionStatus.disconnected,
      ),
    );
  }

  Future<void> _onTeardownVoiceSessionLocal(
    TeardownVoiceSessionLocalEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final resolvedSessionId =
        event.sessionId ?? state.session?.id ?? state.sessionId;
    await _teardownLocalSession(sessionId: resolvedSessionId);

    emit(
      state.copyWith(
        activeSpeakers: const [],
        isLiveKitConnected: false,
        isMicOn: false,
        participantQualities: const {},
        rtcStatus: RtcConnectionStatus.disconnected,
      ),
    );
  }

  Future<void> _onAppSessionCurrentUserChanged(
    AppSessionCurrentUserChangedEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    if (state.currentUserId == event.userId) {
      return;
    }

    if (event.userId == null) {
      await _teardownLocalSession(sessionId: state.session?.id);
      emit(
        state.copyWith(
          currentUserId: null,
          session: null,
          mySessions: const [],
          activeSpeakers: const [],
          isLiveKitConnected: false,
          isMicOn: false,
          participantQualities: const {},
          rtcStatus: RtcConnectionStatus.disconnected,
        ),
      );
      return;
    }

    emit(state.copyWith(currentUserId: event.userId));
  }

  Future<void> _teardownLocalSession({
    int? sessionId,
    bool leaveSignalRGroup = true,
  }) async {
    try {
      await intercomEngine.detachSession(stopAudio: true);
    } catch (e) {
      debugPrint('⚠️ [VoiceSessionBloc] Intercom teardown warning: $e');
    }

    if (leaveSignalRGroup && sessionId != null && sessionId > 0) {
      try {
        await signalRService.leaveVoiceSessionGroup(sessionId.toString());
      } catch (e) {
        debugPrint('⚠️ [VoiceSessionBloc] SignalR leave warning: $e');
      }
    }

    if (_activeCallKitId != null) {
      try {
        await callKitIncomingService.endCall(_activeCallKitId!);
      } catch (e) {
        debugPrint('⚠️ [VoiceSessionBloc] CallKit end warning: $e');
      } finally {
        _activeCallKitId = null;
      }
    }

    // ── Battery Optimization: Arka plan servisini durdur ──
    try {
      unawaited(AppBackgroundService.stop());
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    _syncTimer?.cancel();
    await _realtimeSubscription?.cancel();
    await _refreshSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _appSessionUserIdSubscription?.cancel();
    await _intercomStateSubscription?.cancel();
    return super.close();
  }

  bool _isNotFoundFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('404') ||
        normalized.contains('not found') ||
        normalized.contains('bulunamad');
  }

  Future<void> _onVoiceSessionNotFoundDetected(
    VoiceSessionNotFoundDetectedEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    _notFoundLocked = true;
    _stopSyncTimer();
    await _teardownLocalSession(sessionId: state.session?.id);
    emit(
      state.copyWith(
        status: VoiceSessionStatus.left,
        session: null,
        activeSpeakers: const [],
        isLiveKitConnected: false,
        isMicOn: false,
        participantQualities: const {},
        rtcStatus: RtcConnectionStatus.disconnected,
        message: event.message.isEmpty
            ? 'Grup artık mevcut değil. Güvenli çıkış yapıldı.'
            : event.message,
      ),
    );
  }

  // ============================================================
  // Intercom handlers
  // ============================================================

  Future<void> _onConnectToLiveKit(
    ConnectToLiveKitEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    await intercomEngine.forceSwitchToSfu(reason: 'manual');
  }

  Future<void> _onDisconnectFromLiveKit(
    DisconnectFromLiveKitEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    await intercomEngine.detachSession(stopAudio: true);
  }

  Future<void> _onToggleMicrophone(
    ToggleMicrophoneEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    await intercomEngine.toggleMic();
  }

  void _onIntercomStateChanged(
    IntercomStateChangedEvent event,
    Emitter<VoiceSessionState> emit,
  ) {
    final intercom = event.intercomState;
    final isSfu =
        intercom.transport == IntercomTransport.sfu ||
        intercom.rtcStatus == RtcConnectionStatus.sfuConnected;

    // [NEW] Handle Permission Failure from Intercom Engine
    if (intercom.lastFailure?.code == IntercomFailureCode.permissionsDenied) {
      emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: 'Mikrofon izni gerekli', // Detected by VoiceStabilityHandler
          rtcStatus: intercom.rtcStatus,
          isMicOn: false, // Force mic off on permission failure
          activeSpeakers: intercom.activeSpeakerIds,
          isLiveKitConnected: isSfu,
        ),
      );
      return;
    }

    // Update state based on intercom changes
    emit(
      state.copyWith(
        rtcStatus: intercom.rtcStatus,
        isMicOn: intercom.micEnabled, // Restore original mic state
        activeSpeakers: intercom.activeSpeakerIds,
        isLiveKitConnected: isSfu,
      ),
    );
  }

  Future<void> _onClearSessionData(
    ClearSessionDataEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    _notFoundLocked = false;
    emit(const VoiceSessionState());
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final activeSessionId = state.session?.id;
      if (activeSessionId != null && activeSessionId > 0) {
        add(GetVoiceSessionDetailsEvent(activeSessionId, force: true));
        debugPrint(
          '[Realtime-F2][Bloc] Running periodic background sync for session: $activeSessionId',
        );
      } else {
        _stopSyncTimer();
      }
    });
  }

  void _stopSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Smart Refresh Priority: Reason'a göre full refresh gerekip gerekmediğini belirler
  bool _shouldTriggerFullRefresh(String reason) {
    // Bu reason'lar UserJoined/Left/Disconnected delta event'leriyle
    // zaten anlık olarak handle ediliyor — ek full refresh gereksiz.
    // Backend'deki gerçek reason string'leriyle eşleştirilmiştir.
    const membershipReasons = {
      'join_session', // JoinSessionAsync
      'leave_session', // LeaveSessionAsync
      'invite_response_accepted', // RespondToInviteAsync → Accepted
      'invite_response_rejected', // RespondToInviteAsync → Rejected
    };

    if (membershipReasons.contains(reason)) {
      return false; // Delta event yeterli, double-refresh önlenir
    }

    // Yapısal değişiklikler → full refresh zorunlu
    const structuralReasons = {
      'role_update', // PromoteUserAsync / DemoteUserAsync
      'transfer_host', // TransferHostAsync
      'kick_user', // KickUserAsync
      'invite_users', // InviteUsersAsync
      'session_settings_updated', // ayar değişikliği
      'session_ended', // oturum kapandı
    };

    if (structuralReasons.contains(reason)) {
      return true;
    }

    // Bilinmeyen reason → güvenli tarafta kal
    return true;
  }
}
