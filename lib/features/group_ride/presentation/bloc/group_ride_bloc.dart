import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_group_ride_usecase.dart';
import '../../domain/usecases/delete_group_ride_usecase.dart';
import '../../domain/usecases/get_active_group_rides_usecase.dart';
import '../../domain/usecases/update_group_ride_usecase.dart';
import '../../domain/usecases/get_group_ride_by_id_usecase.dart';
import '../../domain/entities/group_ride_entity.dart';
import 'package:moto_comm_app_1/features/voice_session/domain/usecases/get_voice_session_details_usecase.dart';
import 'package:moto_comm_app_1/features/attendance_management/domain/usecases/leave_group_ride_usecase.dart';
import 'package:moto_comm_app_1/core/services/communication_realtime_bus.dart';
import 'package:moto_comm_app_1/core/services/communication_refresh_coordinator.dart';
import 'package:moto_comm_app_1/core/services/signalr_service.dart';
import 'group_ride_event.dart';
import 'group_ride_state.dart';

import 'package:rxdart/rxdart.dart';

class GroupRideBloc extends Bloc<GroupRideEvent, GroupRideState> {
  final CreateGroupRideUseCase createGroupRideUseCase;
  final DeleteGroupRideUseCase deleteGroupRideUseCase;
  final GetActiveGroupRidesUseCase getActiveGroupRidesUseCase;
  final LeaveGroupRideUseCase leaveGroupRideUseCase;
  final SignalRService signalRService;
  final CommunicationRealtimeBus realtimeBus;
  final CommunicationRefreshCoordinator refreshCoordinator;
  final GetGroupRideByIdUseCase? getGroupRideByIdUseCase;
  final UpdateGroupRideUseCase updateGroupRideUseCase;
  final GetVoiceSessionDetailsUseCase getVoiceSessionDetailsUseCase;

  StreamSubscription? _realtimeSubscription;
  StreamSubscription? _refreshSubscription;
  StreamSubscription? _errorSubscription;
  bool _notFoundLocked = false;

  final Map<int, int> _rideSessionCache = {};
  final Map<int, DateTime> _rideNotFoundUntil = {};
  static const Duration _rideNotFoundCooldown = Duration(seconds: 20);

  void _cacheRideSession(GroupRideEntity ride) {
    final sessionId = ride.sessionId;
    if (sessionId != null && sessionId > 0) {
      _rideSessionCache[ride.id] = sessionId;
    }
  }

  void _cacheRideSessionsFromList(List<GroupRideEntity> rides) {
    for (final ride in rides) {
      _cacheRideSession(ride);
    }
  }

  int? _resolveSessionId(int rideId, {int? explicitSessionId}) {
    if (explicitSessionId != null && explicitSessionId > 0) {
      return explicitSessionId;
    }

    final cached = _rideSessionCache[rideId];
    if (cached != null && cached > 0) {
      return cached;
    }

    final currentState = state;
    if (currentState is GroupRideSuccess && currentState.ride.id == rideId) {
      return currentState.ride.sessionId;
    }
    if (currentState is GroupRideCreatedSync &&
        currentState.ride.id == rideId) {
      return currentState.sessionId;
    }
    if (currentState is GroupRidesLoaded) {
      for (final ride in currentState.rides) {
        if (ride.id == rideId) {
          return ride.sessionId;
        }
      }
    }

    return null;
  }

  int? _resolveRideIdBySessionId(int sessionId) {
    if (sessionId <= 0) return null;

    for (final entry in _rideSessionCache.entries) {
      if (entry.value == sessionId) {
        return entry.key;
      }
    }

    final currentState = state;
    if (currentState is GroupRidesLoaded) {
      for (final ride in currentState.rides) {
        if (ride.sessionId == sessionId) {
          return ride.id;
        }
      }
    }

    if (currentState is GroupRideSuccess &&
        currentState.ride.sessionId == sessionId) {
      return currentState.ride.id;
    }

    return null;
  }

  bool _isNotFoundFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('404') ||
        normalized.contains('not found') ||
        normalized.contains('bulunamad');
  }

  bool _isRideInNotFoundCooldown(int rideId) {
    final until = _rideNotFoundUntil[rideId];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _rideNotFoundUntil.remove(rideId);
      return false;
    }
    return true;
  }

  void _markRideNotFound(int rideId) {
    _rideNotFoundUntil[rideId] = DateTime.now().add(_rideNotFoundCooldown);
  }

  GroupRideBloc({
    required this.createGroupRideUseCase,
    required this.deleteGroupRideUseCase,
    required this.getActiveGroupRidesUseCase,
    required this.leaveGroupRideUseCase,
    required this.signalRService,
    required this.realtimeBus,
    required this.refreshCoordinator,
    this.getGroupRideByIdUseCase,
    required this.updateGroupRideUseCase,
    required this.getVoiceSessionDetailsUseCase,
  }) : super(GroupRideInitial()) {
    on<InitializeGroupRideEvent>(_onInitializeGroupRide);
    on<CreateGroupRideEvent>(_onCreateGroupRide);
    on<LoadActiveGroupRidesEvent>(
      _onLoadActiveGroupRides,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .asyncExpand(mapper),
    );
    on<DeleteGroupRideEvent>(_onDeleteGroupRide);
    on<LeaveGroupRideEvent>(_onLeaveGroupRide);
    on<RideTerminatedReceived>(_onRideTerminated);
    on<HostChangedReceived>(_onHostChanged);
    on<JoinSignalRGroupEvent>(_onJoinSignalRGroup);
    on<UpdateGroupRideEvent>(_onUpdateGroupRide);
    on<LoadGroupRideDetailsEvent>(_onLoadGroupRideDetails);
    on<GroupRideUpdatedReceived>(_onGroupRideUpdatedReceived);
    on<GroupRideNotFoundDetected>(_onGroupRideNotFoundDetected);
    on<ClearGroupDataEvent>(_onClearGroupData);

    _realtimeSubscription = realtimeBus.events.listen((event) {
      if (isClosed) return;
      if (_notFoundLocked) return;

      if (event is RideTerminatedRealtimeEvent) {
        add(RideTerminatedReceived(event.rideId.toString()));
        return;
      }

      if (event is RideCreatedRealtimeEvent) {
        refreshCoordinator.requestGroupRidesRefresh(
          reason: 'rt_ride_created',
        );
        return;
      }

      if (event is UserJoinedVoiceSessionRealtimeEvent) {
        final rideId = _resolveRideIdBySessionId(event.sessionId);
        if (rideId != null) {
          add(
            GroupRideUpdatedReceived(
              rideId.toString(),
              version: event.version,
            ),
          );
        }
        return;
      }

      if (event is UserLeftVoiceSessionRealtimeEvent) {
        final rideId = _resolveRideIdBySessionId(event.sessionId);
        if (rideId != null) {
          add(
            GroupRideUpdatedReceived(
              rideId.toString(),
              version: event.version,
            ),
          );
        }
        return;
      }

      if (event is HostChangedRealtimeEvent) {
        add(HostChangedReceived(event.data));
        return;
      }

      if (event is GroupRideUpdatedRealtimeEvent) {
        add(
          GroupRideUpdatedReceived(
            event.rideId.toString(),
            version: event.version,
          ),
        );
      }
    });

    _refreshSubscription = refreshCoordinator.requests.listen((request) {
      if (isClosed) return;
      if (_notFoundLocked) return;
      if (request.target == CommunicationRefreshTarget.groupRides) {
        add(LoadActiveGroupRidesEvent(force: request.force));
        return;
      }

      if (request.target == CommunicationRefreshTarget.reconnectInvalidation) {
        add(const LoadActiveGroupRidesEvent(force: true));
      }
    });

    _errorSubscription = refreshCoordinator.errors.listen((event) {
      if (isClosed) return;
      if (event.category != RealtimeErrorCategory.notFound) return;
      if (event.source != RealtimeStateCoordinator.sourceGroupRide) return;
      add(GroupRideNotFoundDetected(event.message));
    });
  }

  Future<void> _onInitializeGroupRide(
    InitializeGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    if (_notFoundLocked) return;

    if (event.rideId > 0) {
      add(JoinSignalRGroupEvent(event.rideId, sessionId: event.sessionId));
      add(LoadGroupRideDetailsEvent(event.rideId, force: true));
      return;
    }

    final sessionId = event.sessionId;
    if (sessionId == null || sessionId <= 0) {
      emit(const GroupRideFailure('Geçersiz Grup veya Oturum ID'));
      return;
    }

    emit(GroupRideResolvingId(sessionId));

    final result = await refreshCoordinator.runGroupRideLookup(
      sessionId,
      () => getVoiceSessionDetailsUseCase(sessionId),
      force: true,
      throttleWindow: Duration.zero,
    );

    int? resolvedRideId;
    String? failureMessage;
    result.fold(
      (failure) => failureMessage = failure.message,
      (session) {
        final rideId = session.rideId;
        if (rideId != null && rideId > 0) {
          resolvedRideId = rideId;
        }
      },
    );

    if (resolvedRideId == null || resolvedRideId! <= 0) {
      emit(GroupRideFailure(failureMessage ?? 'Sürüş bilgisi çözülemedi.'));
      return;
    }

    add(JoinSignalRGroupEvent(resolvedRideId!, sessionId: sessionId));
    add(LoadGroupRideDetailsEvent(resolvedRideId!, force: true));
  }

  @override
  Future<void> close() async {
    await _realtimeSubscription?.cancel();
    await _refreshSubscription?.cancel();
    await _errorSubscription?.cancel();
    return super.close();
  }

  Future<void> _onCreateGroupRide(
    CreateGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(GroupRideLoading());

    final rideResult = await createGroupRideUseCase.execute(event.request);

    await rideResult.fold(
      (failure) async => emit(GroupRideFailure(failure.message)),
      (ride) async {
        _cacheRideSession(ride);
        await signalRService.joinRideGroup(ride.id.toString());

        if (ride.sessionId != null && ride.sessionId! > 0) {
          await signalRService.joinVoiceSessionGroup(
            ride.sessionId!.toString(),
          );
          emit(GroupRideCreatedSync(ride, ride.sessionId!));
        } else {
          emit(
            GroupRideSuccess(
              ride,
              "Grup olusturuldu (Ses oturumu bilgisi alinamadi)",
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
    if (_notFoundLocked && !event.force) {
      return;
    }

    final hasLoadedList = state is GroupRidesLoaded;
    if (!hasLoadedList || event.force) {
      emit(GroupRideLoading());
    }
    final result = await refreshCoordinator.runGroupRides(
      () => getActiveGroupRidesUseCase.execute(),
      force: event.force,
      // 4s cooldown to reduce repeated list-fetch bursts.
      throttleWindow: const Duration(seconds: 4),
    );
    result.fold((failure) => emit(GroupRideFailure(failure.message)), (rides) {
      _cacheRideSessionsFromList(rides);
      emit(GroupRidesLoaded(rides));
    });
  }

  Future<void> _onDeleteGroupRide(
    DeleteGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    final signalrSessionId = _resolveSessionId(
      event.rideId,
      explicitSessionId: event.sessionId,
    );

    emit(GroupRideLoading());
    final result = await deleteGroupRideUseCase.execute(event.rideId);

    await result.fold(
      (failure) async => emit(GroupRideFailure(failure.message)),
      (_) async {
        await signalRService.leaveRideGroup(event.rideId.toString());
        if (signalrSessionId != null && signalrSessionId > 0) {
          await signalRService.leaveVoiceSessionGroup(
            signalrSessionId.toString(),
          );
        }
        _rideSessionCache.remove(event.rideId);
        emit(GroupRideDeleted(rideId: event.rideId));
      },
    );
  }

  Future<void> _onLeaveGroupRide(
    LeaveGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    final signalrSessionId = _resolveSessionId(
      event.rideId,
      explicitSessionId: event.sessionId,
    );

    emit(GroupRideLoading());
    final result = await leaveGroupRideUseCase.call(event.rideId);

    await result.fold(
      (failure) async => emit(GroupRideFailure(failure.message)),
      (_) async {
        await signalRService.leaveRideGroup(event.rideId.toString());
        if (signalrSessionId != null && signalrSessionId > 0) {
          await signalRService.leaveVoiceSessionGroup(
            signalrSessionId.toString(),
          );
        }
        _rideSessionCache.remove(event.rideId);
        emit(GroupRideLeft(rideId: event.rideId));
      },
    );
  }

  Future<void> _onRideTerminated(
    RideTerminatedReceived event,
    Emitter<GroupRideState> emit,
  ) async {
    final rideId = int.tryParse(event.rideId ?? '');
    if (rideId != null) {
      await signalRService.leaveRideGroup(rideId.toString());

      final signalrSessionId = _resolveSessionId(rideId);
      if (signalrSessionId != null && signalrSessionId > 0) {
        await signalRService.leaveVoiceSessionGroup(
          signalrSessionId.toString(),
        );
      }
      _rideSessionCache.remove(rideId);
    }

    final currentState = state;
    if (rideId != null && currentState is GroupRidesLoaded) {
      final nextRides = currentState.rides
          .where((ride) => ride.id != rideId)
          .toList();
      if (nextRides.length != currentState.rides.length) {
        emit(GroupRidesLoaded(nextRides));
        return;
      }
    }

    emit(GroupRideTerminated(rideId: rideId));
  }

  Future<void> _onJoinSignalRGroup(
    JoinSignalRGroupEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    await signalRService.joinRideGroup(event.rideId.toString());

    final signalrSessionId = _resolveSessionId(
      event.rideId,
      explicitSessionId: event.sessionId,
    );
    if (signalrSessionId != null && signalrSessionId > 0) {
      _rideSessionCache[event.rideId] = signalrSessionId;
      await signalRService.joinVoiceSessionGroup(signalrSessionId.toString());
    }
  }

  Future<void> _onUpdateGroupRide(
    UpdateGroupRideEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    emit(GroupRideLoading());

    final rideEntity = GroupRideEntity(
      id: event.rideId,
      title: event.request.title,
      description: event.request.description,
      organizerId: event.organizerId,
      startDateTime: event.request.startDateTime,
      endDateTime: event.request.endDateTime,
      startLocation: event.request.startLocation,
      startLatitude: event.request.startLatitude,
      startLongitude: event.request.startLongitude,
      endLocation: event.request.endLocation,
      endLatitude: event.request.endLatitude,
      endLongitude: event.request.endLongitude,
      maxParticipants: event.request.maxParticipants,
      status: 'Active',
      difficulty: event.request.difficulty,
      ridingStyle: event.request.ridingStyle,
      isPrivate: event.request.privacy == 'Private',
    );

    final result = await updateGroupRideUseCase.execute(
      event.rideId,
      rideEntity,
    );

    result.fold((failure) => emit(GroupRideFailure(failure.message)), (ride) {
      _cacheRideSession(ride);
      emit(GroupRideSuccess(ride, "Grup turu basariyla guncellendi"));
      add(const LoadActiveGroupRidesEvent());
    });
  }

  Future<void> _onLoadGroupRideDetails(
    LoadGroupRideDetailsEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    if (_notFoundLocked && !event.force) return;
    if (getGroupRideByIdUseCase == null) return;
    if (_isRideInNotFoundCooldown(event.rideId)) return;

    emit(GroupRideLoading());

    const maxRetries = 3;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      final result = await refreshCoordinator.runGroupRideDetails(
        event.rideId,
        () => getGroupRideByIdUseCase!.execute(event.rideId),
        // First call uses in-flight dedup; retries bypass cache to ensure a real retry.
        force: event.force || attempt > 0,
        // Phase 5 scope: in-flight dedup only, no throttle cache yet.
        throttleWindow: Duration.zero,
      );
      String? failureMessage;
      GroupRideEntity? loadedRide;
      result.fold(
        (failure) => failureMessage = failure.message,
        (ride) => loadedRide = ride,
      );

      if (loadedRide != null) {
        _rideNotFoundUntil.remove(event.rideId);
        _cacheRideSession(loadedRide!);
        emit(GroupRideSuccess(loadedRide!, "Grup detaylari yuklendi"));
        return;
      }

      if (failureMessage != null && _isNotFoundFailure(failureMessage!)) {
        refreshCoordinator.reportNotFound(
          message: 'Grup artık mevcut değil',
          source: RealtimeStateCoordinator.sourceGroupRide,
          dedupKey: 'group_ride_404:${event.rideId}',
        );
        _markRideNotFound(event.rideId);
        emit(const GroupRideFailure('Grup artık mevcut değil. Güvenli çıkış yapın.'));
        return;
      }

      if (attempt == maxRetries) {
        emit(GroupRideFailure(failureMessage ?? "Grup detaylari yuklenemedi"));
        return;
      }

      await Future.delayed(Duration(seconds: 1 << attempt));
    }
  }

  Future<void> _onGroupRideUpdatedReceived(
    GroupRideUpdatedReceived event,
    Emitter<GroupRideState> emit,
  ) async {
    if (_notFoundLocked) {
      return;
    }

    final rideId = int.tryParse(event.rideId);
    if (rideId == null || getGroupRideByIdUseCase == null) {
      return;
    }
    if (_isRideInNotFoundCooldown(rideId)) {
      add(const LoadActiveGroupRidesEvent());
      return;
    }

    final result = await refreshCoordinator.runGroupRideDetails(
      rideId,
      () => getGroupRideByIdUseCase!.execute(rideId),
      throttleWindow: Duration.zero,
    );

    result.fold(
      (failure) {
        if (_isNotFoundFailure(failure.message)) {
          refreshCoordinator.reportNotFound(
            message: 'Grup artık mevcut değil',
            source: RealtimeStateCoordinator.sourceGroupRide,
            dedupKey: 'group_ride_404:$rideId',
          );
          return;
        }
        add(const LoadActiveGroupRidesEvent());
      },
      (ride) {
        _cacheRideSession(ride);

        final currentState = state;
        if (currentState is GroupRidesLoaded) {
          final index = currentState.rides.indexWhere((r) => r.id == ride.id);
          if (index == -1) {
            add(const LoadActiveGroupRidesEvent());
            return;
          }

          final patched = List<GroupRideEntity>.from(currentState.rides);
          patched[index] = ride;
          debugPrint(
            '[Realtime-F2][Bloc] Applying patch for ${ride.id} - Version: ${event.version ?? '-'}',
          );
          emit(GroupRidesLoaded(patched));
          return;
        }

        if (currentState is GroupRideSuccess &&
            currentState.ride.id == ride.id) {
          emit(GroupRideSuccess(ride, currentState.message));
          return;
        }

        add(const LoadActiveGroupRidesEvent());
      },
    );
  }

  Future<void> _onGroupRideNotFoundDetected(
    GroupRideNotFoundDetected event,
    Emitter<GroupRideState> emit,
  ) async {
    _notFoundLocked = true;
    _rideNotFoundUntil.clear();
    emit(GroupRideFailure(event.message.isEmpty ? 'Grup artık mevcut değil. Güvenli çıkış yapın.' : event.message));
  }

  Future<void> _onHostChanged(
    HostChangedReceived event,
    Emitter<GroupRideState> emit,
  ) async {
    final rideId = int.tryParse(event.data['rideId']?.toString() ?? '');
    if (rideId != null) {
      add(GroupRideUpdatedReceived(rideId.toString()));
      return;
    }
    add(const LoadActiveGroupRidesEvent());
  }

  Future<void> _onClearGroupData(
    ClearGroupDataEvent event,
    Emitter<GroupRideState> emit,
  ) async {
    _notFoundLocked = false;
    _rideSessionCache.clear();
    _rideNotFoundUntil.clear();
    emit(GroupRideInitial());
  }
}
