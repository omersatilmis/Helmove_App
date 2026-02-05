import 'package:equatable/equatable.dart';

/// GroupRide Bloc events
abstract class GroupRideEvent extends Equatable {
  const GroupRideEvent();

  @override
  List<Object?> get props => [];
}

/// Kullanıcının grup turlarını yükle
class LoadMyGroupRides extends GroupRideEvent {
  const LoadMyGroupRides();
}

/// Yakındaki grup turlarını yükle
class LoadNearbyGroupRides extends GroupRideEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const LoadNearbyGroupRides({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

/// Grup turu katılımcılarını yükle
class LoadGroupRideParticipants extends GroupRideEvent {
  final int rideId;

  const LoadGroupRideParticipants(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

/// Yeni grup turu oluştur
class CreateGroupRide extends GroupRideEvent {
  final Map<String, dynamic> data;

  const CreateGroupRide(this.data);

  @override
  List<Object?> get props => [data];
}

/// Grup turuna katıl
class JoinGroupRide extends GroupRideEvent {
  final int rideId;
  final String? joinMessage;

  const JoinGroupRide(this.rideId, {this.joinMessage});

  @override
  List<Object?> get props => [rideId, joinMessage];
}

class LeaveGroupRide extends GroupRideEvent {
  final int rideId;

  const LeaveGroupRide(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

/// Grup turunu güncelle
class UpdateGroupRide extends GroupRideEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateGroupRide(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

/// Grup turunu sil
class DeleteGroupRide extends GroupRideEvent {
  final int id;

  const DeleteGroupRide(this.id);

  @override
  List<Object?> get props => [id];
}

/// Grup turu detaylarını yükle
class LoadGroupRideDetails extends GroupRideEvent {
  final int id;

  const LoadGroupRideDetails(this.id);

  @override
  List<Object?> get props => [id];
}

/// Aktif grup turlarını yükle
class LoadActiveGroupRides extends GroupRideEvent {
  const LoadActiveGroupRides();
}
