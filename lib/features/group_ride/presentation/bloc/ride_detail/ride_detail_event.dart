import 'package:equatable/equatable.dart';

/// [Tur Detayı] bloc event'leri.
abstract class RideDetailEvent extends Equatable {
  const RideDetailEvent();

  @override
  List<Object?> get props => [];
}

/// İlk yükleme: detay + katılım durumu + katılımcılar.
class RideDetailRequested extends RideDetailEvent {
  final int rideId;
  const RideDetailRequested(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

/// Pull-to-refresh / aksiyon sonrası sessiz yenileme.
class RideDetailRefreshed extends RideDetailEvent {
  const RideDetailRefreshed();
}

/// Kullanıcı turdan katılma isteği gönderir.
class JoinRequested extends RideDetailEvent {
  final String? message;
  const JoinRequested({this.message});

  @override
  List<Object?> get props => [message];
}

/// Kullanıcı turdan ayrılır / katılma isteğini geri çeker.
class LeaveRequested extends RideDetailEvent {
  const LeaveRequested();
}

/// Organizatör bekleyen bir katılımcıyı onaylar.
class ParticipantApproved extends RideDetailEvent {
  final int userId;
  const ParticipantApproved(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Organizatör bekleyen bir katılımcıyı reddeder.
class ParticipantRejected extends RideDetailEvent {
  final int userId;
  const ParticipantRejected(this.userId);

  @override
  List<Object?> get props => [userId];
}
