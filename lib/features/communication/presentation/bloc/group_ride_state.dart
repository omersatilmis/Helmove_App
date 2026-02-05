import 'package:equatable/equatable.dart';
import '../../domain/entities/group_ride_entity.dart';
import '../../domain/entities/group_ride_participant_entity.dart';

/// GroupRide Bloc states
abstract class GroupRideState extends Equatable {
  const GroupRideState();

  @override
  List<Object?> get props => [];
}

/// Başlangıç durumu
class GroupRideInitial extends GroupRideState {
  const GroupRideInitial();
}

/// Yükleniyor durumu
class GroupRideLoading extends GroupRideState {
  const GroupRideLoading();
}

/// Kullanıcının grup turları yüklendi
class MyGroupRidesLoaded extends GroupRideState {
  final List<GroupRideEntity> rides;

  const MyGroupRidesLoaded(this.rides);

  @override
  List<Object?> get props => [rides];
}

/// Yakındaki grup turları yüklendi
class NearbyGroupRidesLoaded extends GroupRideState {
  final List<GroupRideEntity> rides;

  const NearbyGroupRidesLoaded(this.rides);

  @override
  List<Object?> get props => [rides];
}

/// Grup turu katılımcıları yüklendi
class GroupRideParticipantsLoaded extends GroupRideState {
  final int rideId;
  final List<GroupRideParticipantEntity> participants;

  const GroupRideParticipantsLoaded({
    required this.rideId,
    required this.participants,
  });

  @override
  List<Object?> get props => [rideId, participants];
}

/// Grup turu oluşturuldu
class GroupRideCreated extends GroupRideState {
  final GroupRideEntity ride;

  const GroupRideCreated(this.ride);

  @override
  List<Object?> get props => [ride];
}

/// Grup turuna katılım başarılı
class GroupRideJoined extends GroupRideState {
  final int rideId;

  const GroupRideJoined(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

/// Grup turundan ayrılma başarılı
class GroupRideLeft extends GroupRideState {
  final int rideId;

  const GroupRideLeft(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

/// Hata durumu
class GroupRideError extends GroupRideState {
  final String message;

  const GroupRideError(this.message);

  @override
  List<Object?> get props => [message];
}
