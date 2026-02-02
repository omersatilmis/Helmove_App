import '../../domain/entities/notification_entity.dart';

class NotificationDto {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final int? relatedId;
  final int? senderId;
  final String? senderUsername;
  final String? senderProfileImage;

  NotificationDto({
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

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      type: json['type'],
      relatedId: json['relatedId'],
      senderId: json['senderId'],
      senderUsername: json['senderUsername'],
      senderProfileImage: json['senderProfileImage'],
    );
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      title: title,
      message: message,
      isRead: isRead,
      createdAt: createdAt,
      type: type,
      relatedId: relatedId,
      senderId: senderId,
      senderUsername: senderUsername,
      senderProfileImage: senderProfileImage,
    );
  }
}
