import 'package:equatable/equatable.dart';
import '../../domain/entities/group_ride_entity.dart';

abstract class GroupRideState extends Equatable {
  const GroupRideState();

  @override
  List<Object?> get props => [];
}

class GroupRideInitial extends GroupRideState {}

class GroupRideLoading extends GroupRideState {}

class GroupRideResolvingId extends GroupRideState {
  final int sessionId;

  const GroupRideResolvingId(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

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

class GroupRideDeleted extends GroupRideState {
  final int? rideId;

  const GroupRideDeleted({this.rideId});

  @override
  List<Object?> get props => [rideId];
}

class GroupRideTerminated extends GroupRideState {
  final int? rideId;

  const GroupRideTerminated({this.rideId});

  @override
  List<Object?> get props => [rideId];
}

class GroupRideLeft extends GroupRideState {
  final int? rideId;

  const GroupRideLeft({this.rideId});

  @override
  List<Object?> get props => [rideId];
}

class GroupRideKicked extends GroupRideState {
  final String message;
  const GroupRideKicked({this.message = "Gruptan atıldınız."});
  @override
  List<Object?> get props => [message];
}

class GroupRideAdminChanged extends GroupRideState {
  final String message;
  const GroupRideAdminChanged(this.message);
  @override
  List<Object?> get props => [message];
}

/// Yaşam döngüsü (status) aksiyonu başarılı oldu — geçici geri bildirim state'i.
/// UI bunu yeşil snackbar olarak gösterir; ardından gelen ride reload
/// (GroupRideSuccess) güncel durumu yansıtır.
class GroupRideStatusChanged extends GroupRideState {
  final int rideId;
  final String message;
  const GroupRideStatusChanged(this.rideId, this.message);
  @override
  List<Object?> get props => [rideId, message];
}
