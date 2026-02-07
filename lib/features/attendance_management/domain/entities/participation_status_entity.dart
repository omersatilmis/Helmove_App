import 'package:equatable/equatable.dart';

class ParticipationStatusEntity extends Equatable {
  final bool isParticipating;
  final String? status; // Pending, Approved, Rejected, None
  final String? joinMessage;
  final DateTime? requestDate;

  const ParticipationStatusEntity({
    required this.isParticipating,
    this.status,
    this.joinMessage,
    this.requestDate,
  });

  @override
  List<Object?> get props => [
    isParticipating,
    status,
    joinMessage,
    requestDate,
  ];
}
