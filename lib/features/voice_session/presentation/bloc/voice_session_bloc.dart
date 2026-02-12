import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_voice_session_usecase.dart';
import '../../domain/usecases/join_voice_session_usecase.dart';
import '../../domain/usecases/leave_voice_session_usecase.dart';
import '../../domain/usecases/invite_to_voice_session_usecase.dart';
import '../../domain/usecases/get_voice_session_details_usecase.dart';
import '../../domain/usecases/get_my_voice_sessions_usecase.dart';
import '../../domain/usecases/accept_voice_session_invitation_usecase.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/livekit_api.dart';
import '../../../../core/services/livekit_room_service.dart';
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
  final AcceptVoiceSessionInvitationUseCase acceptVoiceSessionInvitationUseCase;
  final RejectVoiceSessionInvitationUseCase rejectVoiceSessionInvitationUseCase;
  final EndVoiceSessionUseCase endVoiceSessionUseCase;
  final SignalRService signalRService;
  final KickUserUseCase kickUserUseCase;
  final MuteUserUseCase muteUserUseCase;
  final TransferHostUseCase transferHostUseCase;

  // LiveKit SFU (Faz 3)
  final LiveKitApi liveKitApi;
  final LiveKitRoomService liveKitRoomService;

  StreamSubscription? _rideTerminatedSubscription;
  StreamSubscription? _rideCreatedSubscription;
  StreamSubscription? _userJoinedSubscription;

  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _hostChangedSubscription;
  StreamSubscription? _voiceSessionRefreshSubscription;
  StreamSubscription? _groupRideUpdatedSubscription;

  // LiveKit stream subscriptions
  StreamSubscription? _lkConnectionSubscription;
  StreamSubscription? _lkSpeakersSubscription;
  StreamSubscription? _lkMicSubscription;

  VoiceSessionBloc({
    required this.createVoiceSessionUseCase,
    required this.joinVoiceSessionUseCase,
    required this.leaveVoiceSessionUseCase,
    required this.inviteToVoiceSessionUseCase,
    required this.getVoiceSessionDetailsUseCase,
    required this.getMyVoiceSessionsUseCase,
    required this.acceptVoiceSessionInvitationUseCase,
    required this.rejectVoiceSessionInvitationUseCase,
    required this.endVoiceSessionUseCase,
    required this.signalRService,
    required this.kickUserUseCase,
    required this.muteUserUseCase,
    required this.transferHostUseCase,
    required this.liveKitApi,
    required this.liveKitRoomService,
  }) : super(const VoiceSessionState()) {
    // Listen to SignalR events
    signalRService.setOnUserJoinedVoiceSession((userId, voiceSessionId) {
      if (!isClosed) {
        add(VoiceSessionParticipantJoinedEvent(userId, roomId: voiceSessionId));
      }
    });

    signalRService.setOnUserLeftVoiceSession((userId, voiceSessionId) {
      if (!isClosed) {
        add(VoiceSessionParticipantLeftEvent(userId, roomId: voiceSessionId));
      }
    });

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
          // Canlı oturum detaylarını da güncelle
          if (state.session != null) {
            add(GetVoiceSessionDetailsEvent(state.session!.id));
          }
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
          // Canlı oturum detaylarını da güncelle
          if (state.session != null) {
            add(GetVoiceSessionDetailsEvent(state.session!.id));
          }
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // ... (lines 135-336 unchanged) ...

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

            // Always refresh session details — GroupPage listens for this
            add(GetVoiceSessionDetailsEvent(sessionId));
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

    // Initialize SignalR
    signalRService.init();

    on<CreateVoiceSessionEvent>(_onCreateVoiceSession);
    on<JoinVoiceSessionEvent>(_onJoinVoiceSession);
    on<LeaveVoiceSessionEvent>(_onLeaveVoiceSession);
    on<InviteUsersEvent>(_onInviteUsers);
    on<GetVoiceSessionDetailsEvent>(_onGetVoiceSessionDetails);
    on<GetMyVoiceSessionsEvent>(_onGetMyVoiceSessions);
    on<AcceptVoiceSessionInviteEvent>(_onAcceptVoiceSessionInvite);

    // New Handlers
    on<KickUserEvent>(_onKickUser);
    on<MuteUserEvent>(_onMuteUser);

    on<TransferHostEvent>(_onTransferHost);
    on<VoiceSessionHostChanged>(_onHostChanged);

    // LiveKit event handlers (Faz 3)
    on<ConnectToLiveKitEvent>(_onConnectToLiveKit);
    on<DisconnectFromLiveKitEvent>(_onDisconnectFromLiveKit);
    on<ToggleMicrophoneEvent>(_onToggleMicrophone);
    on<LiveKitMicStateChangedEvent>(_onLiveKitMicStateChanged);
    on<LiveKitConnectionChangedEvent>(_onLiveKitConnectionChanged);
    on<ActiveSpeakersChangedEvent>(_onActiveSpeakersChanged);

    on<VoiceSessionParticipantJoinedEvent>((event, emit) {
      if (state.status == VoiceSessionStatus.detailsLoaded &&
          state.session != null) {
        final currentSessionId = state.session.id;

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
        final currentSessionId = state.session.id;

        if (event.roomId != null) {
          if (event.roomId == currentSessionId.toString()) {
            add(GetVoiceSessionDetailsEvent(currentSessionId));
          }
        } else {
          add(GetVoiceSessionDetailsEvent(currentSessionId));
        }
      }
    });
  }

  Future<void> _onCreateVoiceSession(
    CreateVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
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

    // 2. PROACTIVE DISCONNECT: Kill LiveKit immediately to free audio/resources
    // Fire & Forget style or awaited but inside a try-catch so it doesn't block backend logic
    try {
      debugPrint(
        "🚀 [VoiceSessionBloc] Forcefully disconnecting LiveKit before API call...",
      );
      await _disconnectLiveKitInternal(); // Helper method for clean disconnect
    } catch (e) {
      debugPrint("⚠️ [VoiceSessionBloc] LiveKit disconnect warning: $e");
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

  /// Helper to cleaner disconnect logic
  Future<void> _disconnectLiveKitInternal() async {
    _lkConnectionSubscription?.cancel();
    _lkSpeakersSubscription?.cancel();
    _lkMicSubscription?.cancel();
    await liveKitRoomService.disconnect();
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
        emit(
          state.copyWith(
            status: VoiceSessionStatus.detailsLoaded,
            session: session,
          ),
        );
      },
    );
  }

  Future<void> _onGetMyVoiceSessions(
    GetMyVoiceSessionsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
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

  Future<void> _onAcceptVoiceSessionInvite(
    AcceptVoiceSessionInviteEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(state.copyWith(status: VoiceSessionStatus.loading));
    final result = await acceptVoiceSessionInvitationUseCase(event.sessionId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: VoiceSessionStatus.error,
          message: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: VoiceSessionStatus.inviteAccepted,
          sessionId: event.sessionId,
        ),
      ),
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
      final currentSessionId = state.session.id;
      add(GetVoiceSessionDetailsEvent(currentSessionId));
    }
  }

  @override
  Future<void> close() {
    _rideTerminatedSubscription?.cancel();
    _rideCreatedSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _hostChangedSubscription?.cancel();
    _voiceSessionRefreshSubscription?.cancel();
    _groupRideUpdatedSubscription?.cancel();
    // LiveKit cleanup
    _lkConnectionSubscription?.cancel();
    _lkSpeakersSubscription?.cancel();
    _lkMicSubscription?.cancel();
    liveKitRoomService.disconnect();
    return super.close();
  }

  // ============================================================
  // LiveKit SFU Handlers (Faz 3)
  // ============================================================

  Future<void> _onConnectToLiveKit(
    ConnectToLiveKitEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      debugPrint(
        '🎙️ [VoiceSessionBloc] Fetching LiveKit token for room: ${event.roomName}',
      );

      // 1. Backend'den token al
      final tokenData = await liveKitApi.getToken(
        roomName: event.roomName,
        displayName: event.displayName,
      );

      final token = tokenData['token'] ?? '';
      final url = tokenData['url'] ?? '';

      if (token.isEmpty || url.isEmpty) {
        emit(state.copyWith(liveKitError: 'LiveKit token alınamadı'));
        return;
      }

      // 2. LiveKit room'a bağlan
      debugPrint('🎙️ [VoiceSessionBloc] Connecting to LiveKit: $url');
      await liveKitRoomService.connect(url, token);

      // 3. Stream'leri dinle
      _lkConnectionSubscription?.cancel();
      _lkConnectionSubscription = liveKitRoomService.connectionStateStream
          .listen((state) {
            if (!isClosed) {
              add(LiveKitConnectionChangedEvent(state.name));
            }
          });

      _lkSpeakersSubscription?.cancel();
      _lkSpeakersSubscription = liveKitRoomService.activeSpeakersStream.listen((
        speakers,
      ) {
        if (!isClosed) {
          final ids = speakers.map((s) => s.identity).toList();
          add(ActiveSpeakersChangedEvent(ids));
        }
      });

      _lkMicSubscription?.cancel();
      _lkMicSubscription = liveKitRoomService.isMicEnabledStream.listen((
        enabled,
      ) {
        if (!isClosed) {
          add(LiveKitMicStateChangedEvent(enabled));
        }
      });

      // State'i güncelle - Session verisi korunur!
      emit(
        state.copyWith(
          isLiveKitConnected: true,
          isMicOn: liveKitRoomService.isMicrophoneEnabled,
          liveKitError: null,
        ),
      );

      debugPrint('✅ [VoiceSessionBloc] LiveKit connected successfully');
    } catch (e) {
      debugPrint('❌ [VoiceSessionBloc] LiveKit connection failed: $e');
      emit(
        state.copyWith(
          liveKitError: 'LiveKit bağlantı hatası: $e',
          isLiveKitConnected: false,
        ),
      );
    }
  }

  Future<void> _onDisconnectFromLiveKit(
    DisconnectFromLiveKitEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    _lkConnectionSubscription?.cancel();
    _lkSpeakersSubscription?.cancel();
    _lkMicSubscription?.cancel();
    await liveKitRoomService.disconnect();

    emit(state.copyWith(isLiveKitConnected: false, activeSpeakers: []));
    debugPrint('👋 [VoiceSessionBloc] LiveKit disconnected');
  }

  Future<void> _onToggleMicrophone(
    ToggleMicrophoneEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    await liveKitRoomService.toggleMicrophone();
    // emit is handled by the stream listener -> _onLiveKitMicStateChanged
  }

  void _onLiveKitMicStateChanged(
    LiveKitMicStateChangedEvent event,
    Emitter<VoiceSessionState> emit,
  ) {
    if (state.isMicOn != event.isEnabled) {
      emit(state.copyWith(isMicOn: event.isEnabled));
    }
  }

  void _onLiveKitConnectionChanged(
    LiveKitConnectionChangedEvent event,
    Emitter<VoiceSessionState> emit,
  ) {
    debugPrint(
      '📡 [VoiceSessionBloc] LiveKit connection: ${event.connectionState}',
    );
    if (event.connectionState == 'disconnected') {
      emit(state.copyWith(isLiveKitConnected: false, activeSpeakers: []));
    }
  }

  void _onActiveSpeakersChanged(
    ActiveSpeakersChangedEvent event,
    Emitter<VoiceSessionState> emit,
  ) {
    emit(state.copyWith(activeSpeakers: event.speakerIdentities));
  }
}
