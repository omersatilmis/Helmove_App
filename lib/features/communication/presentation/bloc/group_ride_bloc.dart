import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_group_ride_usecase.dart';
import '../../domain/usecases/get_group_ride_participants_usecase.dart';
import '../../domain/usecases/get_my_group_rides_usecase.dart';
import '../../domain/usecases/get_nearby_group_rides_usecase.dart';
import '../../domain/usecases/join_group_ride_usecase.dart';
import '../../domain/usecases/leave_group_ride_usecase.dart';
import '../../domain/usecases/update_group_ride_usecase.dart';
import '../../domain/usecases/delete_group_ride_usecase.dart';
import '../../domain/usecases/get_group_ride_by_id_usecase.dart';
import '../../domain/usecases/get_active_group_rides_usecase.dart';
import 'group_ride_event.dart';
import 'group_ride_state.dart';

/// GroupRide Bloc - Grup turları için state yönetimi
class GroupRideBloc extends Bloc<GroupRideEvent, GroupRideState> {
  final GetMyGroupRidesUseCase getMyGroupRidesUseCase;
  final GetNearbyGroupRidesUseCase getNearbyGroupRidesUseCase;
  final GetGroupRideParticipantsUseCase getGroupRideParticipantsUseCase;
  final CreateGroupRideUseCase createGroupRideUseCase;
  final JoinGroupRideUseCase joinGroupRideUseCase;
  final LeaveGroupRideUseCase leaveGroupRideUseCase;
  final UpdateGroupRideUseCase updateGroupRideUseCase;
  final DeleteGroupRideUseCase deleteGroupRideUseCase;
  final GetGroupRideByIdUseCase getGroupRideByIdUseCase;
  final GetActiveGroupRidesUseCase getActiveGroupRidesUseCase;

  GroupRideBloc({
    required this.getMyGroupRidesUseCase,
    required this.getNearbyGroupRidesUseCase,
    required this.getGroupRideParticipantsUseCase,
    required this.createGroupRideUseCase,
    required this.joinGroupRideUseCase,
    required this.leaveGroupRideUseCase,
    required this.updateGroupRideUseCase,
    required this.deleteGroupRideUseCase,
    required this.getGroupRideByIdUseCase,
    required this.getActiveGroupRidesUseCase,
  }) : super(const GroupRideInitial()) {
    on<LoadMyGroupRides>(_onLoadMyGroupRides);
    on<LoadNearbyGroupRides>(_onLoadNearbyGroupRides);
    on<LoadGroupRideParticipants>(_onLoadGroupRideParticipants);
    on<CreateGroupRide>(_onCreateGroupRide);
    on<JoinGroupRide>(_onJoinGroupRide);
    on<LeaveGroupRide>(_onLeaveGroupRide);
    on<UpdateGroupRide>(_onUpdateGroupRide);
    on<DeleteGroupRide>(_onDeleteGroupRide);
    on<LoadGroupRideDetails>(_onLoadGroupRideDetails);
    on<LoadActiveGroupRides>(_onLoadActiveGroupRides);
  }

  Future<void> _onLoadMyGroupRides(
    LoadMyGroupRides event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await getMyGroupRidesUseCase();
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (rides) => emit(MyGroupRidesLoaded(rides)),
    );
  }

  Future<void> _onLoadNearbyGroupRides(
    LoadNearbyGroupRides event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await getNearbyGroupRidesUseCase(
      latitude: event.latitude,
      longitude: event.longitude,
      radiusKm: event.radiusKm,
    );
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (rides) => emit(NearbyGroupRidesLoaded(rides)),
    );
  }

  Future<void> _onLoadGroupRideParticipants(
    LoadGroupRideParticipants event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await getGroupRideParticipantsUseCase(event.rideId);
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (participants) => emit(
        GroupRideParticipantsLoaded(
          rideId: event.rideId,
          participants: participants,
        ),
      ),
    );
  }

  Future<void> _onCreateGroupRide(
    CreateGroupRide event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await createGroupRideUseCase(event.data);
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (ride) => emit(GroupRideCreated(ride)),
    );
  }

  Future<void> _onJoinGroupRide(
    JoinGroupRide event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await joinGroupRideUseCase(
      event.rideId,
      joinMessage: event.joinMessage,
    );
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (_) => emit(GroupRideJoined(event.rideId)),
    );
  }

  Future<void> _onLeaveGroupRide(
    LeaveGroupRide event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await leaveGroupRideUseCase(event.rideId);
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (_) => emit(GroupRideLeft(event.rideId)),
    );
  }

  Future<void> _onUpdateGroupRide(
    UpdateGroupRide event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await updateGroupRideUseCase(event.id, event.data);
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (ride) => emit(GroupRideUpdated(ride)),
    );
  }

  Future<void> _onDeleteGroupRide(
    DeleteGroupRide event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await deleteGroupRideUseCase(event.id);
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (_) => emit(GroupRideDeleted(event.id)),
    );
  }

  Future<void> _onLoadGroupRideDetails(
    LoadGroupRideDetails event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await getGroupRideByIdUseCase(event.id);
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (ride) => emit(GroupRideDetailsLoaded(ride)),
    );
  }

  Future<void> _onLoadActiveGroupRides(
    LoadActiveGroupRides event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(const GroupRideLoading());
    final result = await getActiveGroupRidesUseCase();
    result.fold(
      (failure) => emit(GroupRideError(failure.message)),
      (rides) => emit(ActiveGroupRidesLoaded(rides)),
    );
  }
}
