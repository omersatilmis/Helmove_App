import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_group_ride_usecase.dart';
import '../../domain/usecases/delete_group_ride_usecase.dart';
import '../../domain/usecases/get_active_group_rides_usecase.dart';
import 'package:moto_comm_app_1/features/attendance_management/domain/usecases/leave_group_ride_usecase.dart';
import 'package:moto_comm_app_1/core/services/signalr_service.dart';
import 'group_ride_event.dart';
import 'group_ride_state.dart';

class GroupRideBloc extends Bloc<GroupRideEvent, GroupRideState> {
  final CreateGroupRideUseCase createGroupRideUseCase;
  final DeleteGroupRideUseCase deleteGroupRideUseCase;
  final GetActiveGroupRidesUseCase getActiveGroupRidesUseCase;
  final LeaveGroupRideUseCase leaveGroupRideUseCase;
  final SignalRService signalRService;

  StreamSubscription? _rideTerminatedSubscription;
  StreamSubscription? _rideCreatedSubscription;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;

  StreamSubscription? _hostChangedSubscription;

  GroupRideBloc({
    required this.createGroupRideUseCase,
    required this.deleteGroupRideUseCase,
    required this.getActiveGroupRidesUseCase,
    required this.leaveGroupRideUseCase,
    required this.signalRService,
  }) : super(GroupRideInitial()) {
    on<CreateGroupRideEvent>(_onCreateGroupRide);
    on<LoadActiveGroupRidesEvent>(_onLoadActiveGroupRides);
    on<DeleteGroupRideEvent>(_onDeleteGroupRide);
    on<LeaveGroupRideEvent>(_onLeaveGroupRide);

    on<RideTerminatedReceived>(_onRideTerminated);

    on<HostChangedReceived>(_onHostChanged);
    on<JoinSignalRGroupEvent>(_onJoinSignalRGroup);

    // --- SignalR Listeners ---

    // 1. Ride Terminated
    _rideTerminatedSubscription = signalRService.rideTerminatedStream.listen((
      rideId,
    ) {
      try {
        if (!isClosed) {
          add(RideTerminatedReceived(rideId));
          // Also refresh list
          add(const LoadActiveGroupRidesEvent());
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // 2. Ride Created (Refresh List)
    _rideCreatedSubscription = signalRService.rideCreatedStream.listen((_) {
      try {
        if (!isClosed) {
          add(const LoadActiveGroupRidesEvent());
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // 3. User Joined (Refresh List - e.g. participant count)
    _userJoinedSubscription = signalRService.userJoinedStream.listen((userId) {
      try {
        if (!isClosed) {
          add(const LoadActiveGroupRidesEvent());
        }
      } catch (e) {
        // Bloc likely closed
      }
    });

    // 4. User Left (Refresh List)
    _userLeftSubscription = signalRService.userLeftStream.listen((userId) {
      try {
        if (!isClosed) {
          add(const LoadActiveGroupRidesEvent());
        }
      } catch (e) {
        // Bloc likely closed
        // Bloc likely closed
      }
    });

    // 5. Host Changed
    _hostChangedSubscription = signalRService.hostChangedStream.listen((data) {
      try {
        if (!isClosed) {
          add(HostChangedReceived(data));
          add(
            const LoadActiveGroupRidesEvent(),
          ); // Refresh list to update organizer info
        }
      } catch (e) {
        // Bloc likely closed
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
    return super.close();
  }

  Future<void> _onCreateGroupRide(
    CreateGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(GroupRideLoading());

    // 1. Create Group Ride
    final rideResult = await createGroupRideUseCase.execute(event.request);

    await rideResult.fold(
      (failure) async => emit(GroupRideFailure(failure.message)),
      (ride) async {
        // 2. Voice Session is now automatically created by the Backend.
        // We just need to check if we have the ID.
        if (ride.voiceSessionId != null) {
          // Join SignalR Group for specific updates
          await signalRService.joinRideGroup(ride.id.toString());
          emit(GroupRideCreatedSync(ride, ride.voiceSessionId!));
        } else {
          // Fallback if backend didn't create it (shouldn't happen with new logic)
          emit(
            GroupRideSuccess(
              ride,
              "Grup oluşturuldu (Ses oturumu bilgisi alınamadı)",
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadActiveGroupRides(
    LoadActiveGroupRidesEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(GroupRideLoading());
    final result = await getActiveGroupRidesUseCase.execute();
    result.fold(
      (failure) => emit(GroupRideFailure(failure.message)),
      (rides) => emit(GroupRidesLoaded(rides)),
    );
  }

  Future<void> _onDeleteGroupRide(
    DeleteGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(GroupRideLoading());

    // 1. Final Hard Delete
    final result = await deleteGroupRideUseCase.execute(event.rideId);
    result.fold((failure) => emit(GroupRideFailure(failure.message)), (_) {
      // Leave SignalR Group
      signalRService.leaveRideGroup(event.rideId.toString());
      emit(GroupRideDeleted());
    });
  }

  Future<void> _onLeaveGroupRide(
    LeaveGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(GroupRideLoading());
    final result = await leaveGroupRideUseCase.call(event.rideId);
    result.fold((failure) => emit(GroupRideFailure(failure.message)), (_) {
      // Leave SignalR Group
      signalRService.leaveRideGroup(event.rideId.toString());
      emit(GroupRideLeft());
    });
  }

  Future<void> _onRideTerminated(
    RideTerminatedReceived event,
    Emitter<GroupRideState> emit,
  ) async {
    // Leave SignalR Group as the ride is already gone on server
    if (event.rideId != null) {
      await signalRService.leaveRideGroup(event.rideId!);
    }
    emit(GroupRideTerminated());
  }

  Future<void> _onJoinSignalRGroup(
    JoinSignalRGroupEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    await signalRService.joinRideGroup(event.rideId.toString());
  }

  Future<void> _onHostChanged(
    HostChangedReceived event,
    Emitter<GroupRideState> emit,
  ) async {
    // Optionally emit a state to notify UI, but refreshing list is usually enough for the list view.
    // GroupPage handles logic via VoiceSessionBloc usually, but if it listens here too:
    // We could emit a "GroupInfoUpdated" state if needed.
  }
}
