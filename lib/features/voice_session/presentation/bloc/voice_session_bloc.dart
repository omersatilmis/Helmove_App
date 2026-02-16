import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../domain/enums/rtc_state.dart';
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
import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/app_session.dart';
import '../../../../core/services/permissions_service.dart';
import '../../../intercom/domain/intercom_engine.dart';
import '../../../intercom/domain/intercom_models.dart';
import 'voice_session_event.dart';
import 'voice_session_state.dart';

import '../../domain/usecases/reject_voice_session_invitation_usecase.dart';
import '../../domain/usecases/end_voice_session_usecase.dart';
import '../../domain/usecases/kick_user_usecase.dart';
import '../../domain/usecases/mute_user_usecase.dart';
import '../../domain/usecases/transfer_host_usecase.dart';

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
  final CallKitIncomingService callKitIncomingService; // Added
  final KickUserUseCase kickUserUseCase;
  final MuteUserUseCase muteUserUseCase;
  final TransferHostUseCase transferHostUseCase;
  final PermissionsService permissionsService;
  final IntercomEngine intercomEngine;

  String? _activeCallKitId;

  StreamSubscription? _rideTerminatedSubscription;
  StreamSubscription? _rideCreatedSubscription;
  StreamSubscription? _userJoinedSubscription;

  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _hostChangedSubscription;
  StreamSubscription? _voiceSessionRefreshSubscription;
  StreamSubscription? _userForceRemovedSubscription;
  StreamSubscription? _groupRideUpdatedSubscription;
  StreamSubscription? _appSessionUserIdSubscription;

  StreamSubscription? _intercomStateSubscription;

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
    required this.callKitIncomingService, // Added
    required this.kickUserUseCase,
    required this.muteUserUseCase,
    required this.transferHostUseCase,
    required this.permissionsService,
    required this.intercomEngine,
  }) : super(const VoiceSessionState()) {
    // --- SignalR Broadcast Listeners for List Refresh ---

    // 1. Ride Terminated
    _rideTerminatedSubscription = signalRService.rideTerminatedStream.listen((
      rideId,
    ) {
      try {
        if (!isClosed) {
          add(const GetMyVoiceSessionsEvent());
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // 2. Ride Created
    _rideCreatedSubscription = signalRService.rideCreatedStream.listen((_) {
      try {
        if (!isClosed) {
          add(const GetMyVoiceSessionsEvent());
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // 3. User Joined
    _userJoinedSubscription = signalRService.userJoinedStream.listen((userId) {
      try {
        if (!isClosed) {
          add(const GetMyVoiceSessionsEvent());
          add(
            VoiceSessionParticipantJoinedEvent(
              userId,
              roomId: state.session?.id.toString(),
            ),
          );
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // 4. User Left
    _userLeftSubscription = signalRService.userLeftStream.listen((userId) {
      try {
        if (!isClosed) {
          add(const GetMyVoiceSessionsEvent());
          add(
            VoiceSessionParticipantLeftEvent(
              userId,
              roomId: state.session?.id.toString(),
            ),
          );
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // 5. Host Changed
    _hostChangedSubscription = signalRService.hostChangedStream.listen((data) {
      if (!isClosed) {
        add(VoiceSessionHostChanged(data));
      }
    });

    // 6. Voice Session Refresh (Accept/Reject updates)
    _voiceSessionRefreshSubscription = signalRService.voiceSessionRefreshStream
        .listen((sessionId) {
          if (!isClosed) {
            // Refresh session list for CommunicationPage
            add(const GetMyVoiceSessionsEvent());

            // Refresh details only for currently opened session to avoid
            // cross-session state churn and unnecessary API calls.
            if (state.session?.id == sessionId) {
              add(GetVoiceSessionDetailsEvent(sessionId));
            }
          }
        });

    _userForceRemovedSubscription = signalRService.userForceRemovedStream
        .listen((sessionId) {
          if (!isClosed) {
            add(VoiceSessionForceRemovedEvent(sessionId));
          }
        });

    // 7. Group Ride Updated (Name/Desc changes)
    _groupRideUpdatedSubscription = signalRService.groupRideUpdatedStream
        .listen((rideId) {
          if (!isClosed) {
            // Refresh session list
            add(const GetMyVoiceSessionsEvent());
          }
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

    // SignalR artık CallListenerService + AuthProvider tarafından
    // merkezi olarak başlatılıyor. Bloc constructor'da tekrar init etmeye
    // gerek yok — race condition'a yol açıyordu.

    on<CreateVoiceSessionEvent>(_onCreateVoiceSession);
    on<JoinVoiceSessionEvent>(_onJoinVoiceSession);
    on<LeaveVoiceSessionEvent>(_onLeaveVoiceSession);
    on<InviteUsersEvent>(_onInviteUsers);
    on<GetVoiceSessionDetailsEvent>(_onGetVoiceSessionDetails);
    on<GetMyVoiceSessionsEvent>(
      _onGetMyVoiceSessions,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .asyncExpand(mapper),
    );
    on<AcceptVoiceSessionInviteEvent>(_onAcceptVoiceSessionInvite);

    // New Handlers
    on<KickUserEvent>(_onKickUser);
    on<MuteUserEvent>(_onMuteUser);

    on<TransferHostEvent>(_onTransferHost);
    on<VoiceSessionHostChanged>(_onHostChanged);

    on<ConnectToLiveKitEvent>(_onConnectToLiveKit);
    on<DisconnectFromLiveKitEvent>(_onDisconnectFromLiveKit);
    on<ToggleMicrophoneEvent>(_onToggleMicrophone);
    on<IntercomStateChangedEvent>(_onIntercomStateChanged);
    on<AppSessionCurrentUserChangedEvent>(_onAppSessionCurrentUserChanged);

    on<VoiceSessionParticipantJoinedEvent>((event, emit) {
      if (state.status == VoiceSessionStatus.detailsLoaded &&
          state.session != null) {
        final currentSessionId = state.session!.id;

        if (event.roomId != null) {
          if (event.roomId == currentSessionId.toString()) {
            add(GetVoiceSessionDetailsEvent(currentSessionId));
          }
        } else {
          add(GetVoiceSessionDetailsEvent(currentSessionId));
        }
      }
    });
    on<VoiceSessionParticipantLeftEvent>((event, emit) {
      if (state.status == VoiceSessionStatus.detailsLoaded &&
          state.session != null) {
        final currentSessionId = state.session!.id;

        if (event.roomId != null) {
          if (event.roomId == currentSessionId.toString()) {
            add(GetVoiceSessionDetailsEvent(currentSessionId));
          }
        } else {
          add(GetVoiceSessionDetailsEvent(currentSessionId));
        }
      }
    });
    on<VoiceSessionForceRemovedEvent>(_onVoiceSessionForceRemoved);
  }

  Future<void> _onCreateVoiceSession(
    CreateVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final permissionsOk = await permissionsService
        .ensureVoiceSessionPermissions(requestLocation: true);
    if (!permissionsOk) {
      emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: 'Oturum icin gerekli izinler verilmedi',
        ),
      );
      return;
    }

    emit(state.copyWith(status: VoiceSessionStatus.loading));
    final result = await createVoiceSessionUseCase(event.request);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: failure.message,
        ),
      ),
      (sessionId) async {
        await signalRService.joinVoiceSessionGroup(sessionId.toString());

        // START CALLKIT
        final uuid = callKitIncomingService.generateCallKitId();
        _activeCallKitId = uuid;
        await callKitIncomingService.startOutboundCall(
          uuid: uuid,
          handle: "Grup Sürüşü",
          nameCaller: event.request.roomName ?? "Grup Sürüşü",
        );
        // Mark connected immediately as we are creating the room
        await Future.delayed(const Duration(milliseconds: 500));
        await callKitIncomingService.markConnected(uuid);

        emit(
          state.copyWith(
            status: VoiceSessionStatus.created,
            sessionId: sessionId,
          ),
        );
      },
    );
  }

  Future<void> _onJoinVoiceSession(
    JoinVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final permissionsOk = await permissionsService
        .ensureVoiceSessionPermissions(requestLocation: true);
    if (!permissionsOk) {
      emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: 'Oturum icin gerekli izinler verilmedi',
        ),
      );
      return;
    }

    emit(state.copyWith(status: VoiceSessionStatus.loading));
    final result = await joinVoiceSessionUseCase(event.sessionId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: failure.message,
        ),
      ),
      (_) async {
        await signalRService.joinVoiceSessionGroup(event.sessionId.toString());

        // START CALLKIT
        final uuid = callKitIncomingService.generateCallKitId();
        _activeCallKitId = uuid;
        await callKitIncomingService.startOutboundCall(
          uuid: uuid,
          handle: "Grup Sürüşü",
          nameCaller: "Grup Sürüşü",
        );
        await Future.delayed(const Duration(milliseconds: 500));
        await callKitIncomingService.markConnected(uuid);

        emit(
          state.copyWith(
            status: VoiceSessionStatus.joined,
            message: "Odaya başarıyla katılındı",
          ),
        );
      },
    );
  }

  Future<void> _onLeaveVoiceSession(
    LeaveVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    // 1. UI Loading (but transient)
    emit(state.copyWith(status: VoiceSessionStatus.loading));

    // END CALLKIT
    if (_activeCallKitId != null) {
      await callKitIncomingService.endCall(_activeCallKitId!);
      _activeCallKitId = null;
    }

    try {
      await intercomEngine.detachSession(stopAudio: true);
    } catch (e) {
      debugPrint("⚠️ [VoiceSessionBloc] Intercom detach warning: $e");
    }

    // 3. Backend Call
    final result = await leaveVoiceSessionUseCase(event.sessionId);

    // 4. Handle Result with OPTIMISTIC LEAVE
    // Even if backend fails (e.g. timeout), we MUST let the user leave the screen.
    await result.fold(
      (failure) async {
        debugPrint(
          "❌ [VoiceSessionBloc] Backend API failed, but forcing UI leave: ${failure.message}",
        );

        // Clean up SignalR anyway
        await signalRService.leaveVoiceSessionGroup(event.sessionId.toString());

        emit(
          state.copyWith(
            status: VoiceSessionStatus.left, // FORCE LEFT
            sessionId: event.sessionId,
            message: "Oturumdan ayrıldınız (Sunucu: ${failure.message})",
            activeSpeakers: [],
            isLiveKitConnected: false,
            isMicOn: false,
            session: null, // Clear session data
          ),
        );
      },
      (_) async {
        await signalRService.leaveVoiceSessionGroup(event.sessionId.toString());
        emit(
          state.copyWith(
            status: VoiceSessionStatus.left,
            sessionId: event.sessionId,
            message: "Oturumdan başarıyla ayrıldınız",
            activeSpeakers: [],
            isLiveKitConnected: false,
            isMicOn: false,
            session: null, // Clear session data
          ),
        );
      },
    );
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
          message: "Davetler başarıyla gönderildi",
        ),
      ),
    );
  }

  Future<void> _onGetVoiceSessionDetails(
    GetVoiceSessionDetailsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    await _ensureCurrentUserId(emit);

    // Sadece ilk yüklemede loading gösterelim, refreshlerde mevcut data kalsın
    if (state.session == null) {
      emit(state.copyWith(status: VoiceSessionStatus.loading));
    }

    final result = await getVoiceSessionDetailsUseCase(event.sessionId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: failure.message,
        ),
      ),
      (session) async {
        await signalRService.joinVoiceSessionGroup(session.id.toString());
        // Gruptan ayrılan veya reddeden kişileri listeden çıkarıyoruz ki
        // tekrar davet edilebilsinler (UI'da invite butonu aktif olsun).
        final activeParticipants = session.participants.where((p) {
          return p.status != 'Left' && p.status != 'Rejected';
        }).toList();

        final updatedSession = session.copyWith(
          participants: activeParticipants,
        );

        emit(
          state.copyWith(
            status: VoiceSessionStatus.detailsLoaded,
            session: updatedSession,
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
                    p.status == 'Disconnected',
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

          await intercomEngine.attachSession(
            IntercomSessionContext(
              sessionId: session.id,
              roomName: session.roomName,
              hostUserId: session.hostUserId,
              localUserId: currentUserId,
              activeParticipantUserIds: activeIds,
              participants: intercomParticipants,
            ),
          );
        }
      },
    );
  }

  Future<void> _onGetMyVoiceSessions(
    GetMyVoiceSessionsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    await _ensureCurrentUserId(emit);

    emit(state.copyWith(status: VoiceSessionStatus.loading));
    final result = await getMyVoiceSessionsUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: failure.message,
        ),
      ),
      (sessions) => emit(
        state.copyWith(
          status: VoiceSessionStatus.mySessionsLoaded,
          mySessions: sessions,
        ),
      ),
    );
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
    final permissionsOk = await permissionsService
        .ensureVoiceSessionPermissions(requestLocation: true);
    if (!permissionsOk) {
      emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: 'Oturum icin gerekli izinler verilmedi',
        ),
      );
      return;
    }

    emit(state.copyWith(status: VoiceSessionStatus.loading));
    final result = await acceptVoiceSessionInvitationUseCase(event.sessionId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: VoiceSessionStatus.inviteAccepted,
            sessionId: event.sessionId,
          ),
        );
        add(JoinVoiceSessionEvent(event.sessionId));
        add(GetVoiceSessionDetailsEvent(event.sessionId));
      },
    );
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
          message: "Kullanıcı atılamadı: ${failure.message}",
        ),
      ),
      (_) {
        add(GetVoiceSessionDetailsEvent(event.sessionId));
        emit(state.copyWith(message: "Kullanıcı atıldı")); // Transient message
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
          message: "Kullanıcı susturulamadı: ${failure.message}",
        ),
      ),
      (_) => emit(state.copyWith(message: "Kullanıcı susturuldu")),
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
          message: "Host devredilemedi: ${failure.message}",
        ),
      ),
      (_) {
        add(GetVoiceSessionDetailsEvent(event.sessionId));
        emit(state.copyWith(message: "Host yetkisi devredildi"));
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

  Future<void> _onVoiceSessionForceRemoved(
    VoiceSessionForceRemovedEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final currentSessionId = state.session?.id;

    if (currentSessionId != event.sessionId) {
      add(const GetMyVoiceSessionsEvent());
      return;
    }

    try {
      await intercomEngine.detachSession(stopAudio: true);
    } catch (e) {
      debugPrint('⚠️ [VoiceSessionBloc] Force remove detach warning: $e');
    }

    await signalRService.leaveVoiceSessionGroup(event.sessionId.toString());

    // END CALLKIT
    if (_activeCallKitId != null) {
      await callKitIncomingService.endCall(_activeCallKitId!);
      _activeCallKitId = null;
    }

    emit(
      state.copyWith(
        status: VoiceSessionStatus.left,
        sessionId: event.sessionId,
        message: event.reason ?? 'Oturumdan çıkarıldınız',
        activeSpeakers: [],
        isLiveKitConnected: false,
        isMicOn: false,
        session: null,
      ),
    );

    add(const GetMyVoiceSessionsEvent());
  }

  Future<void> _onAppSessionCurrentUserChanged(
    AppSessionCurrentUserChangedEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    if (state.currentUserId == event.userId) {
      return;
    }

    if (event.userId == null) {
      await intercomEngine.detachSession(stopAudio: true);

      // END CALLKIT
      if (_activeCallKitId != null) {
        await callKitIncomingService.endCall(_activeCallKitId!);
        _activeCallKitId = null;
      }
      emit(
        state.copyWith(
          currentUserId: null,
          session: null,
          mySessions: const [],
          activeSpeakers: const [],
          isLiveKitConnected: false,
          isMicOn: false,
        ),
      );
      return;
    }

    emit(state.copyWith(currentUserId: event.userId));
  }

  @override
  Future<void> close() {
    _rideTerminatedSubscription?.cancel();
    _rideCreatedSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _hostChangedSubscription?.cancel();
    _voiceSessionRefreshSubscription?.cancel();
    _userForceRemovedSubscription?.cancel();
    _groupRideUpdatedSubscription?.cancel();
    _appSessionUserIdSubscription?.cancel();
    _intercomStateSubscription?.cancel();
    return super.close();
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

    emit(
      state.copyWith(
        rtcStatus: intercom.rtcStatus,
        isMicOn: intercom.micEnabled,
        activeSpeakers: intercom.activeSpeakerIds,
        isLiveKitConnected: isSfu,
      ),
    );
  }
}
