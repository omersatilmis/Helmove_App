import 'package:equatable/equatable.dart';
import '../../data/dto/create_group_ride_request_dto.dart';

abstract class GroupRideEvent extends Equatable {
  const GroupRideEvent();

  @override
  List<Object?> get props => [];
}

class CreateGroupRideEvent extends GroupRideEvent {
  final CreateGroupRideRequestDto request;

  const CreateGroupRideEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class LoadActiveGroupRidesEvent extends GroupRideEvent {
  final bool force;

  const LoadActiveGroupRidesEvent({this.force = false});

  @override
  List<Object?> get props => [force];
}

class DeleteGroupRideEvent extends GroupRideEvent {
  final int rideId;
  final int? sessionId;
  const DeleteGroupRideEvent(this.rideId, {this.sessionId});

  @override
  List<Object?> get props => [rideId, sessionId];
}

class LeaveGroupRideEvent extends GroupRideEvent {
  final int rideId;
  final int? sessionId;
  const LeaveGroupRideEvent(this.rideId, {this.sessionId});

  @override
  List<Object?> get props => [rideId, sessionId];
}

class RideTerminatedReceived extends GroupRideEvent {
  final String? rideId;
  const RideTerminatedReceived(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class JoinSignalRGroupEvent extends GroupRideEvent {
  final int rideId;
  final int? sessionId;
  const JoinSignalRGroupEvent(this.rideId, {this.sessionId});

  @override
  List<Object?> get props => [rideId, sessionId];
}

class HostChangedReceived extends GroupRideEvent {
  final Map<String, dynamic> data;
  const HostChangedReceived(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateGroupRideEvent extends GroupRideEvent {
  final int rideId;
  final CreateGroupRideRequestDto request;
  final int organizerId;

  const UpdateGroupRideEvent(this.rideId, this.request, this.organizerId);

  @override
  List<Object?> get props => [rideId, request, organizerId];
}

class LoadGroupRideDetailsEvent extends GroupRideEvent {
  final int rideId;
  final bool force;
  const LoadGroupRideDetailsEvent(this.rideId, {this.force = false});

  @override
  List<Object?> get props => [rideId, force];
}

class GroupRideUpdatedReceived extends GroupRideEvent {
  final String rideId;
  final int? version;
  const GroupRideUpdatedReceived(this.rideId, {this.version});

  @override
  List<Object?> get props => [rideId, version];
}

class ClearGroupDataEvent extends GroupRideEvent {
  const ClearGroupDataEvent();
}

class GroupRideNotFoundDetected extends GroupRideEvent {
  final String message;
  const GroupRideNotFoundDetected(this.message);

  @override
  List<Object?> get props => [message];
}

class InitializeGroupRideEvent extends GroupRideEvent {
  final int rideId;
  final int? sessionId;

  const InitializeGroupRideEvent({required this.rideId, this.sessionId});

  @override
  List<Object?> get props => [rideId, sessionId];
}
