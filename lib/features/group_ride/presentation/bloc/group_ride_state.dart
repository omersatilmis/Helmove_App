import 'package:equatable/equatable.dart';
import '../../domain/entities/group_ride_entity.dart';

abstract class GroupRideState extends Equatable {
  const GroupRideState();

  @override
  List<Object?> get props => [];
}

class GroupRideInitial extends GroupRideState {}

class GroupRideLoading extends GroupRideState {}

class GroupRideSuccess extends GroupRideState {
  final GroupRideEntity ride;
  final String message;

  const GroupRideSuccess(this.ride, this.message);

  @override
  List<Object?> get props => [ride, message];
}

class GroupRidesLoaded extends GroupRideState {
  final List<GroupRideEntity> rides;

  const GroupRidesLoaded(this.rides);

  @override
  List<Object?> get props => [rides];
}

class GroupRideFailure extends GroupRideState {
  final String message;

  const GroupRideFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupRideCreatedSync extends GroupRideState {
  final GroupRideEntity ride;
  final int sessionId;

  const GroupRideCreatedSync(this.ride, this.sessionId);

  @override
  List<Object?> get props => [ride, sessionId];
}

class GroupRideDeleted extends GroupRideState {}

class GroupRideTerminated extends GroupRideState {}

class GroupRideLeft extends GroupRideState {}
