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
  final SignalRService signalRService;
  final KickUserUseCase kickUserUseCase;
  final MuteUserUseCase muteUserUseCase;
  final TransferHostUseCase transferHostUseCase;

  VoiceSessionBloc({
    required this.createVoiceSessionUseCase,
    required this.joinVoiceSessionUseCase,
    required this.leaveVoiceSessionUseCase,
    required this.inviteToVoiceSessionUseCase,
    required this.getVoiceSessionDetailsUseCase,
    required this.getMyVoiceSessionsUseCase,
    required this.acceptVoiceSessionInvitationUseCase,
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

  Future<void> _onCreateVoiceSession(
    CreateVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    try {
      final sessionId = await createVoiceSessionUseCase(event.request);

      // Join SignalR Group
      await signalRService.joinRideGroup(sessionId.toString());

      emit(VoiceSessionCreated(sessionId));
    } catch (e) {
      emit(VoiceSessionError(e.toString()));
    }
  }

  Future<void> _onJoinVoiceSession(
    JoinVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    try {
      await joinVoiceSessionUseCase(event.sessionId);

      // Join SignalR Group
      await signalRService.joinRideGroup(event.sessionId.toString());

      emit(const VoiceSessionActionSuccess("Odaya başarıyla katılındı"));
    } catch (e) {
      emit(VoiceSessionError(e.toString()));
    }
  }

  Future<void> _onLeaveVoiceSession(
    LeaveVoiceSessionEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    try {
      await leaveVoiceSessionUseCase(event.sessionId);

      // Leave SignalR Group
      await signalRService.leaveRideGroup(event.sessionId.toString());

      emit(VoiceSessionLeft(event.sessionId));
    } catch (e) {
      emit(VoiceSessionError(e.toString()));
    }
  }

  Future<void> _onInviteUsers(
    InviteUsersEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      await inviteToVoiceSessionUseCase(event.sessionId, event.request);
      // We don't change state here to avoid disrupting the UI
    } catch (e) {
      emit(VoiceSessionError(e.toString()));
    }
  }

  Future<void> _onGetVoiceSessionDetails(
    GetVoiceSessionDetailsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    try {
      final session = await getVoiceSessionDetailsUseCase(event.sessionId);
      emit(VoiceSessionDetailsLoaded(session));
    } catch (e) {
      emit(VoiceSessionError(e.toString()));
    }
  }

  Future<void> _onGetMyVoiceSessions(
    GetMyVoiceSessionsEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    try {
      final sessions = await getMyVoiceSessionsUseCase();
      emit(MyVoiceSessionsLoaded(sessions));
    } catch (e) {
      emit(VoiceSessionError(e.toString()));
    }
  }

  Future<void> _onAcceptVoiceSessionInvite(
    AcceptVoiceSessionInviteEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    emit(VoiceSessionLoading());
    try {
      await acceptVoiceSessionInvitationUseCase(event.sessionId);
      emit(VoiceSessionInviteAccepted(event.sessionId));
    } catch (e) {
      emit(VoiceSessionError(e.toString()));
    }
  }

  Future<void> _onKickUser(
    KickUserEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      await kickUserUseCase(event.sessionId, event.targetUserId);
      // Refresh details to reflect change
      add(GetVoiceSessionDetailsEvent(event.sessionId));
      emit(const VoiceSessionActionSuccess("Kullanıcı atıldı"));
    } catch (e) {
      emit(VoiceSessionError("Kullanıcı atılamadı: $e"));
    }
  }

  Future<void> _onMuteUser(
    MuteUserEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      await muteUserUseCase(event.sessionId, event.targetUserId);
      emit(const VoiceSessionActionSuccess("Kullanıcı susturuldu"));
    } catch (e) {
      emit(VoiceSessionError("Kullanıcı susturulamadı: $e"));
    }
  }

  Future<void> _onTransferHost(
    TransferHostEvent event,
    Emitter<VoiceSessionState> emit,
  ) async {
    try {
      await transferHostUseCase(event.sessionId, event.newHostId);
      // Refresh details to reflect new host
      add(GetVoiceSessionDetailsEvent(event.sessionId));
      emit(const VoiceSessionActionSuccess("Host yetkisi devredildi"));
    } catch (e) {
      emit(VoiceSessionError("Host devredilemedi: $e"));
    }
  }
}
