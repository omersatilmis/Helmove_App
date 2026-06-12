import '../../../attendance_management/domain/entities/group_role.dart';
import '../../domain/entities/voice_session_participant_entity.dart';

class VoiceSessionParticipantModel extends VoiceSessionParticipantEntity {
  const VoiceSessionParticipantModel({
    required super.userId,
    super.username,
    super.firstName,
    super.lastName,
    super.profileImage,
    required super.status,
    super.role = GroupRole.rider,
    super.joinedAt,
    super.phoneBatteryLevel,
    super.intercomBatteryLevel,
    super.signalStrength,
    super.isRemoteMuted,
  });

  factory VoiceSessionParticipantModel.fromJson(Map<String, dynamic> json) {
    // Backend response structure:
    // { userId, user: { id, username, firstName, lastName, profilePictureUrl }, status, joinedAt, role }
    final user = json['user'] as Map<String, dynamic>?;

    // Role parsing
    GroupRole parsedRole = GroupRole.rider;
    if (json['role'] != null) {
      if (json['role'] is int) {
        int roleIndex = json['role'];
        if (roleIndex >= 0 && roleIndex < GroupRole.values.length) {
          parsedRole = GroupRole.values[roleIndex];
        }
      } else if (json['role'] is String) {
        parsedRole = GroupRole.fromString(json['role']);
      }
    }

    // Status can be int (enum) or string
    String statusString;
    final rawStatus = json['status'];
    if (rawStatus is int) {
      // Map enum values: 0=Invited, 1=Accepted, 2=Rejected, 3=Joined, 4=Left, 5=Disconnected, 6=Kicked
      const statusMap = {
        0: 'Invited',
        1: 'Accepted',
        2: 'Rejected',
        3: 'Joined',
        4: 'Left',
        5: 'Disconnected',
        6: 'Kicked',
      };
      statusString = statusMap[rawStatus] ?? 'Unknown';
    } else {
      statusString = rawStatus?.toString() ?? 'Unknown';
    }

    return VoiceSessionParticipantModel(
      userId: json['userId'] ?? user?['id'] ?? 0,
      username: user?['username'],
      firstName: user?['firstName'],
      lastName: user?['lastName'],
      profileImage: user?['profilePictureUrl'],
      status: statusString,
      role: parsedRole,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'])
          : null,
      phoneBatteryLevel: json['phoneBatteryLevel'],
      intercomBatteryLevel: json['intercomBatteryLevel'],
      signalStrength: json['signalStrength'],
      // Backend bu alanı henüz döndürmüyorsa false kalır; bloc tarafında
      // önceki in-memory mute state ile merge edilir.
      isRemoteMuted:
          json['isRemoteMuted'] == true ||
          json['isMuted'] == true ||
          json['isMutedByAdmin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'role': role.index,
      'joinedAt': joinedAt?.toIso8601String(),
      'phoneBatteryLevel': phoneBatteryLevel,
      'intercomBatteryLevel': intercomBatteryLevel,
      'signalStrength': signalStrength,
    };
  }
}
