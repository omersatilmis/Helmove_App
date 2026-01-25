import 'package:equatable/equatable.dart';
import 'message.dart';

class Conversation extends Equatable {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime? lastActivity;

  const Conversation({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    required this.isOnline,
    this.lastSeen,
    this.lastMessage,
    required this.unreadCount,
    this.lastActivity,
  });

  @override
  List<Object?> get props => [
    userId,
    username,
    firstName,
    lastName,
    profilePictureUrl,
    isOnline,
    lastSeen,
    lastMessage,
    unreadCount,
    lastActivity,
  ];
}
