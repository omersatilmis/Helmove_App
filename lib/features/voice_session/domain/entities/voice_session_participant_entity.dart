import 'package:equatable/equatable.dart';

/// Sesli sohbet oturumu katılımcısı entity'si
class VoiceSessionParticipantEntity extends Equatable {
  final int userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String status; // Invited, Accepted, Joined, Left, Rejected
  final DateTime? joinedAt;

  const VoiceSessionParticipantEntity({
    required this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.profileImage,
    required this.status,
    this.joinedAt,
  });

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

  @override
  List<Object?> get props => [userId, username, status, joinedAt];
}
