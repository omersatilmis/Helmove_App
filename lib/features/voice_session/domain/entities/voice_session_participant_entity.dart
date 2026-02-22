import 'package:equatable/equatable.dart';
import '../../../attendance_management/domain/entities/group_role.dart';

/// Sesli sohbet oturumu katılımcısı entity'si
class VoiceSessionParticipantEntity extends Equatable {
  final int userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String status; // Invited, Accepted, Joined, Left, Rejected
  final DateTime? joinedAt;
  final GroupRole role;

  // Real-time metrics
  final int? phoneBatteryLevel;
  final int? intercomBatteryLevel;
  final int? signalStrength;
  final bool isRemoteMuted;

  const VoiceSessionParticipantEntity({
    required this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.profileImage,
    required this.status,
    this.role = GroupRole.rider,
    this.joinedAt,
    this.phoneBatteryLevel,
    this.intercomBatteryLevel,
    this.signalStrength,
    this.isRemoteMuted = false,
  });

  VoiceSessionParticipantEntity copyWith({
    int? userId,
    String? username,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? status,
    GroupRole? role,
    DateTime? joinedAt,
    int? phoneBatteryLevel,
    int? intercomBatteryLevel,
    int? signalStrength,
    bool? isRemoteMuted,
  }) {
    return VoiceSessionParticipantEntity(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      phoneBatteryLevel: phoneBatteryLevel ?? this.phoneBatteryLevel,
      intercomBatteryLevel: intercomBatteryLevel ?? this.intercomBatteryLevel,
      signalStrength: signalStrength ?? this.signalStrength,
      isRemoteMuted: isRemoteMuted ?? this.isRemoteMuted,
    );
  }

  /// Kullanıcının görünen adı
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username ?? 'Bilinmeyen';
  }

  /// Katılımcı şu anda odada mı?
  bool get isJoined => status == 'Joined';

  /// Daveti kabul etmiş mi?
  bool get hasAccepted => status == 'Accepted' || status == 'Joined';

  /// Bağlantısı kopmuş mu? (Ama hâlâ odada)
  bool get isDisconnected => status == 'Disconnected';

  /// Odada mı? (Joined veya Disconnected)
  bool get isInRoom => status == 'Joined' || status == 'Disconnected';

  @override
  List<Object?> get props => [
    userId,
    username,
    status,
    role,
    joinedAt,
    phoneBatteryLevel,
    intercomBatteryLevel,
    signalStrength,
    isRemoteMuted,
  ];
}
