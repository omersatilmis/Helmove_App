/// GroupRide Participant domain entity
class GroupRideParticipantEntity {
  final int id;
  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String status;
  final DateTime joinedAt;
  final String? joinMessage;
  final String? profilePictureUrl;

  const GroupRideParticipantEntity({
    required this.id,
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.joinedAt,
    this.joinMessage,
    this.profilePictureUrl,
  });

  /// Tam ad
  String get fullName => '$firstName $lastName'.trim();

  /// Onaylanmış mı
  bool get isApproved => status == 'Approved';

  /// Beklemede mi
  bool get isPending => status == 'Pending';
}
