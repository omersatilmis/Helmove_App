import '../../domain/entities/participation_status_entity.dart';

class ParticipationStatusModel extends ParticipationStatusEntity {
  const ParticipationStatusModel({
    required super.isParticipating,
    super.status,
    super.joinMessage,
    super.requestDate,
  });

  factory ParticipationStatusModel.fromJson(Map<String, dynamic> json) {
    return ParticipationStatusModel(
      isParticipating: json['isParticipating'] as bool? ?? false,
      status: json['status'] as String?,
      joinMessage: json['joinMessage'] as String?,
      requestDate: json['requestDate'] != null
          ? DateTime.parse(json['requestDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isParticipating': isParticipating,
      'status': status,
      'joinMessage': joinMessage,
      'requestDate': requestDate?.toIso8601String(),
    };
  }
}
