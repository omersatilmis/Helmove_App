import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:helmove/features/attendance_management/domain/usecases/approve_participant_usecase.dart';
import 'package:helmove/features/attendance_management/domain/usecases/get_participation_status_usecase.dart';
import 'package:helmove/features/attendance_management/domain/usecases/get_ride_participants_usecase.dart';
import 'package:helmove/features/attendance_management/domain/usecases/join_group_ride_usecase.dart';
import 'package:helmove/features/attendance_management/domain/usecases/leave_group_ride_usecase.dart';
import 'package:helmove/features/attendance_management/domain/usecases/reject_participant_usecase.dart';
import 'package:helmove/features/auth/domain/usecases/get_current_user_id_use_case.dart';
import 'package:helmove/features/group_ride/domain/usecases/get_group_ride_by_id_usecase.dart';

import 'ride_detail_event.dart';
import 'ride_detail_state.dart';

/// [Tur Detayı] bloc'u. Grup dışındaki kullanıcının göreceği detay ekranını
/// besler: tam detay + kullanıcının katılım durumu + katılımcı listesi, ve
/// katıl/ayrıl/onayla/reddet aksiyonları.
class RideDetailBloc extends Bloc<RideDetailEvent, RideDetailState> {
  final GetGroupRideByIdUseCase getGroupRideById;
  final GetParticipationStatusUseCase getParticipationStatus;
  final GetRideParticipantsUseCase getRideParticipants;
  final JoinGroupRideUseCase joinGroupRide;
  final LeaveGroupRideUseCase leaveGroupRide;
  final ApproveParticipantUseCase approveParticipant;
  final RejectParticipantUseCase rejectParticipant;
  final GetCurrentUserIdUseCase getCurrentUserId;

  int? _rideId;
  int _seq = 0;

  RideDetailBloc({
    required this.getGroupRideById,
    required this.getParticipationStatus,
    required this.getRideParticipants,
    required this.joinGroupRide,
    required this.leaveGroupRide,
    required this.approveParticipant,
    required this.rejectParticipant,
    required this.getCurrentUserId,
  }) : super(const RideDetailState()) {
    on<RideDetailRequested>(_onRequested);
    on<RideDetailRefreshed>(_onRefreshed);
    on<JoinRequested>(_onJoin);
    on<LeaveRequested>(_onLeave);
    on<ParticipantApproved>(_onApprove);
    on<ParticipantRejected>(_onReject);
  }

  int get _nextSeq => ++_seq;

  Future<void> _onRequested(
    RideDetailRequested event,
    Emitter<RideDetailState> emit,
  ) async {
    _rideId = event.rideId;
    emit(state.copyWith(status: RideDetailStatus.loading));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    RideDetailRefreshed event,
    Emitter<RideDetailState> emit,
  ) async {
    await _load(emit);
  }

  /// Detayı (zorunlu) + katılım durumu + katılımcıları (toleranslı) yükler.
  Future<void> _load(Emitter<RideDetailState> emit) async {
    final rideId = _rideId;
    if (rideId == null) return;

    final userId = await getCurrentUserId();

    final rideResult = await getGroupRideById.execute(rideId);
    final ride = rideResult.fold((_) => null, (r) => r);
    if (ride == null) {
      emit(
        state.copyWith(
          status: RideDetailStatus.failure,
          error: rideResult.fold((l) => l.message, (_) => null) ??
              'Tur detayı yüklenemedi.',
        ),
      );
      return;
    }

    // Katılım durumu ve katılımcı listesi opsiyonel: backend non-member'a 403
    // dönebilir; hata durumunda boş/null ile devam et (ekran yine de çalışır).
    final participationResult = await getParticipationStatus(rideId);
    final participation = participationResult.fold((_) => null, (p) => p);

    final participantsResult = await getRideParticipants(rideId);
    final participants = participantsResult.fold((_) => null, (list) => list);

    emit(
      RideDetailState(
        status: RideDetailStatus.success,
        ride: ride,
        participation: participation,
        participants: participants ?? const [],
        currentUserId: userId,
      ),
    );
  }

  Future<void> _onJoin(
    JoinRequested event,
    Emitter<RideDetailState> emit,
  ) async {
    final rideId = _rideId;
    if (rideId == null || state.actionInProgress) return;

    emit(state.copyWith(actionInProgress: true));
    final result = await joinGroupRide(rideId, joinMessage: event.message);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          actionInProgress: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
          feedbackSeq: _nextSeq,
        ),
      ),
      (_) async {
        await _load(emit);
        emit(
          state.copyWith(
            actionInProgress: false,
            feedbackMessage: 'Katılma isteğin gönderildi.',
            feedbackIsError: false,
            feedbackSeq: _nextSeq,
          ),
        );
      },
    );
  }

  Future<void> _onLeave(
    LeaveRequested event,
    Emitter<RideDetailState> emit,
  ) async {
    final rideId = _rideId;
    if (rideId == null || state.actionInProgress) return;

    emit(state.copyWith(actionInProgress: true));
    final result = await leaveGroupRide(rideId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          actionInProgress: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
          feedbackSeq: _nextSeq,
        ),
      ),
      (_) async {
        await _load(emit);
        emit(
          state.copyWith(
            actionInProgress: false,
            feedbackMessage: 'Turdan ayrıldın.',
            feedbackIsError: false,
            feedbackSeq: _nextSeq,
          ),
        );
      },
    );
  }

  Future<void> _onApprove(
    ParticipantApproved event,
    Emitter<RideDetailState> emit,
  ) async {
    final rideId = _rideId;
    if (rideId == null || state.actionInProgress) return;

    emit(state.copyWith(actionInProgress: true));
    final result = await approveParticipant(rideId, event.userId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          actionInProgress: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
          feedbackSeq: _nextSeq,
        ),
      ),
      (_) async {
        await _load(emit);
        emit(
          state.copyWith(
            actionInProgress: false,
            feedbackMessage: 'Katılımcı onaylandı.',
            feedbackIsError: false,
            feedbackSeq: _nextSeq,
          ),
        );
      },
    );
  }

  Future<void> _onReject(
    ParticipantRejected event,
    Emitter<RideDetailState> emit,
  ) async {
    final rideId = _rideId;
    if (rideId == null || state.actionInProgress) return;

    emit(state.copyWith(actionInProgress: true));
    final result = await rejectParticipant(rideId, event.userId);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          actionInProgress: false,
          feedbackMessage: failure.message,
          feedbackIsError: true,
          feedbackSeq: _nextSeq,
        ),
      ),
      (_) async {
        await _load(emit);
        emit(
          state.copyWith(
            actionInProgress: false,
            feedbackMessage: 'Katılımcı reddedildi.',
            feedbackIsError: false,
            feedbackSeq: _nextSeq,
          ),
        );
      },
    );
  }
}
