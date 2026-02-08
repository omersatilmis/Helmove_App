import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_voice_session_usecase.dart';
import '../../domain/usecases/join_voice_session_usecase.dart';
import '../../domain/usecases/leave_voice_session_usecase.dart';
import '../../domain/usecases/invite_to_voice_session_usecase.dart';
import '../../domain/usecases/get_voice_session_details_usecase.dart';
import '../../domain/usecases/get_my_voice_sessions_usecase.dart';
import '../../domain/usecases/accept_voice_session_invitation_usecase.dart';
import '../../../../core/services/signalr_service.dart';
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

  StreamSubscription? _rideTerminatedSubscription;
  StreamSubscription? _rideCreatedSubscription;
  StreamSubscription? _userJoinedSubscription;

  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _hostChangedSubscription;

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
  }) : super(VoiceSessionInitial()) {
    // Listen to SignalR events
    signalRService.setOnUserJoinedRide((userId, rideId) {
      if (!isClosed) {
        add(VoiceSessionParticipantJoinedEvent(userId, roomId: rideId));
      }
    });

    signalRService.setOnUserLeftRide((userId, rideId) {
      if (!isClosed) {
        add(VoiceSessionParticipantLeftEvent(userId, roomId: rideId));
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
        }
      } catch (e) {
        // Bloc likely closed
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
    signalRService.voiceSessionRefreshStream.listen((sessionId) {
      if (!isClosed) {
        // ALWAYS refresh the list for CommunicationPage
        add(const GetMyVoiceSessionsEvent());

        // If we are currently viewing this session, refresh details
        if (state is VoiceSessionDetailsLoaded) {
          final currentSessionId =
              (state as VoiceSessionDetailsLoaded).session.id;
          if (currentSessionId == sessionId) {
            add(GetVoiceSessionDetailsEvent(sessionId));
          }
        }
      }
    });

    // 7. Group Ride Updated (Name/Desc changes)
    signalRService.groupRideUpdatedStream.listen((rideId) {
      if (!isClosed) {
        // Refresh session list
        add(const GetMyVoiceSessionsEvent());

        // Refresh details if current session is for this ride
        if (state is VoiceSessionDetailsLoaded) {
          final session = (state as VoiceSessionDetailsLoaded).session;
          if (session.groupRideId?.toString() == rideId) {
            add(GetVoiceSessionDetailsEvent(session.id));
          }
        }
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

    on<VoiceSessionParticipantJoinedEvent>((event, emit) {
      // Refresh session details to get updated list
      if (state is VoiceSessionDetailsLoaded) {
        final currentSessionId =
            (state as VoiceSessionDetailsLoaded).session.id;

        // If we have roomId (from SignalR active context), check if it matches
        if (event.roomId != null) {
          if (event.roomId == currentSessionId.toString()) {
            add(GetVoiceSessionDetailsEvent(currentSessionId));
          }
        } else {
          // Fallback if no roomId provided (backward compatibility or error)
          add(GetVoiceSessionDetailsEvent(currentSessionId));
        }
      }
    });
    on<VoiceSessionParticipantLeftEvent>((event, emit) {
      if (state is VoiceSessionDetailsLoaded) {
        final currentSessionId =
            (state as VoiceSessionDetailsLoaded).session.id;

        // If we have roomId (from SignalR active context), check if it matches
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

  @override
  Future<void> close() {
    _rideTerminatedSubscription?.cancel();
    _rideCreatedSubscription?.cancel();
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _hostChangedSubscription?.cancel();
    // signalRService handles its own subscriptions or we can add local ones if needed
    // The .listen pattern used for groupRideUpdatedStream above should ideally be matched
    // with a stream subscription stored in a variable if we want manual control,
    // but Bloc listeners are usually fine as long as they check !isClosed.
    return super.close();
  }

  Future<void> _onCreateVoiceSession(
    CreateVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    final result = await createVoiceSessionUseCase(event.request);
    await result.fold(
      (failure) async => emit(VoiceSessionError(failure.message)),
      (sessionId) async {
        // Join SignalR Group
        await signalRService.joinRideGroup(sessionId.toString());
        emit(VoiceSessionCreated(sessionId));
      },
    );
  }

  Future<void> _onJoinVoiceSession(
    JoinVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    final result = await joinVoiceSessionUseCase(event.sessionId);
    await result.fold(
      (failure) async => emit(VoiceSessionError(failure.message)),
      (_) async {
        // Join SignalR Group
        await signalRService.joinRideGroup(event.sessionId.toString());
        emit(const VoiceSessionActionSuccess("Odaya başarıyla katılındı"));
      },
    );
  }

  Future<void> _onLeaveVoiceSession(
    LeaveVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    final result = await leaveVoiceSessionUseCase(event.sessionId);
    await result.fold(
      (failure) async => emit(VoiceSessionError(failure.message)),
      (_) async {
        // Leave SignalR Group
        await signalRService.leaveRideGroup(event.sessionId.toString());
        emit(VoiceSessionLeft(event.sessionId));
      },
    );
  }

  Future<void> _onInviteUsers(
    InviteUsersEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await inviteToVoiceSessionUseCase(
      event.sessionId,
      event.request,
    );
    result.fold(
      (failure) => emit(VoiceSessionError(failure.message)),
      (_) => null, // Success is silent in this case as per original code
    );
  }

  Future<void> _onGetVoiceSessionDetails(
    GetVoiceSessionDetailsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    final result = await getVoiceSessionDetailsUseCase(event.sessionId);
    result.fold(
      (failure) => emit(VoiceSessionError(failure.message)),
      (session) => emit(VoiceSessionDetailsLoaded(session)),
    );
  }

  Future<void> _onGetMyVoiceSessions(
    GetMyVoiceSessionsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    final result = await getMyVoiceSessionsUseCase();
    result.fold(
      (failure) => emit(VoiceSessionError(failure.message)),
      (sessions) => emit(MyVoiceSessionsLoaded(sessions)),
    );
  }

  Future<void> _onAcceptVoiceSessionInvite(
    AcceptVoiceSessionInviteEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    final result = await acceptVoiceSessionInvitationUseCase(event.sessionId);
    result.fold(
      (failure) => emit(VoiceSessionError(failure.message)),
      (_) => emit(VoiceSessionInviteAccepted(event.sessionId)),
    );
  }

  Future<void> _onKickUser(
    KickUserEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await kickUserUseCase(event.sessionId, event.targetUserId);
    result.fold(
      (failure) =>
          emit(VoiceSessionError("Kullanıcı atılamadı: ${failure.message}")),
      (_) {
        add(GetVoiceSessionDetailsEvent(event.sessionId));
        emit(const VoiceSessionActionSuccess("Kullanıcı atıldı"));
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
        VoiceSessionError("Kullanıcı susturulamadı: ${failure.message}"),
      ),
      (_) => emit(const VoiceSessionActionSuccess("Kullanıcı susturuldu")),
    );
  }

  Future<void> _onTransferHost(
    TransferHostEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    final result = await transferHostUseCase(event.sessionId, event.newHostId);
    result.fold(
      (failure) =>
          emit(VoiceSessionError("Host devredilemedi: ${failure.message}")),
      (_) {
        add(GetVoiceSessionDetailsEvent(event.sessionId));
        emit(const VoiceSessionActionSuccess("Host yetkisi devredildi"));
      },
    );
  }

  Future<void> _onHostChanged(
    VoiceSessionHostChanged event,
    Emitter<VoiceSessionState> emit,
  ) async {
    if (state is VoiceSessionDetailsLoaded) {
      final currentSessionId = (state as VoiceSessionDetailsLoaded).session.id;
      add(GetVoiceSessionDetailsEvent(currentSessionId));
    }
  }
}
