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
  const LoadActiveGroupRidesEvent();
}

class DeleteGroupRideEvent extends GroupRideEvent {
  final int rideId;
  final int? voiceSessionId;
  const DeleteGroupRideEvent(this.rideId, {this.voiceSessionId});

  @override
  List<Object?> get props => [rideId, voiceSessionId];
}

class LeaveGroupRideEvent extends GroupRideEvent {
  final int rideId;
  const LeaveGroupRideEvent(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class RideTerminatedReceived extends GroupRideEvent {
  final String? rideId;
  const RideTerminatedReceived(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class JoinSignalRGroupEvent extends GroupRideEvent {
  final int rideId;
  const JoinSignalRGroupEvent(this.rideId);

  @override
  List<Object?> get props => [rideId];
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
  const LoadGroupRideDetailsEvent(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

class GroupRideUpdatedReceived extends GroupRideEvent {
  final String rideId;
  const GroupRideUpdatedReceived(this.rideId);

  @override
  List<Object?> get props => [rideId];
}
