import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? type; // 'like', 'comment', 'follow', 'system' etc.
  final int? relatedId; // PostID, UserID etc.
  final int? senderId;
  final String? senderUsername;
  final String? senderProfileImage;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.relatedId,
    this.senderId,
    this.senderUsername,
    this.senderProfileImage,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    isRead,
    createdAt,
    type,
    relatedId,
    senderId,
    senderUsername,
    senderProfileImage,
  ];
}
