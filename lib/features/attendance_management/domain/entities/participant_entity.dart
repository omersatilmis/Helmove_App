import 'package:equatable/equatable.dart';
import 'group_role.dart';

class ParticipantEntity extends Equatable {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final String status; // Pending, Approved, Rejected
  final DateTime? requestDate;

  const ParticipantEntity({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    required this.status,
    required this.role,
    this.requestDate,
  });

  final GroupRole role;

  @override
  List<Object?> get props => [
    userId,
    username,
    firstName,
    lastName,
    profileImageUrl,
    status,
    requestDate,
  ];
}
