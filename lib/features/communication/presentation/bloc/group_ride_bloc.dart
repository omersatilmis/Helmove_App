import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_group_ride_usecase.dart';
import '../../domain/usecases/get_group_ride_participants_usecase.dart';
import '../../domain/usecases/get_my_group_rides_usecase.dart';
import '../../domain/usecases/get_nearby_group_rides_usecase.dart';
import '../../domain/usecases/join_group_ride_usecase.dart';
import '../../domain/usecases/leave_group_ride_usecase.dart';
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

  GroupRideBloc({
    required this.getMyGroupRidesUseCase,
    required this.getNearbyGroupRidesUseCase,
    required this.getGroupRideParticipantsUseCase,
    required this.createGroupRideUseCase,
    required this.joinGroupRideUseCase,
    required this.leaveGroupRideUseCase,
  }) : super(const GroupRideInitial()) {
    on<LoadMyGroupRides>(_onLoadMyGroupRides);
    on<LoadNearbyGroupRides>(_onLoadNearbyGroupRides);
    on<LoadGroupRideParticipants>(_onLoadGroupRideParticipants);
    on<CreateGroupRide>(_onCreateGroupRide);
    on<JoinGroupRide>(_onJoinGroupRide);
    on<LeaveGroupRide>(_onLeaveGroupRide);
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
}
