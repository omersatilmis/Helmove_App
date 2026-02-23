import 'dart:convert';
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
  final String? dataJson;

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
    this.dataJson,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    String? normalizeDataJson(Map<String, dynamic> source) {
      final raw = source['dataJson'];
      if (raw is String) {
        final text = raw.trim();
        if (text.isNotEmpty && text != 'null') {
          return text;
        }
      } else if (raw != null) {
        return jsonEncode(raw);
      }

      final fallbackPayload = <String, dynamic>{};
      final sessionId = parseNullableInt(
        source['sessionId'] ?? source['voiceSessionId'],
      );
      final rideId = parseNullableInt(
        source['rideId'] ?? source['groupRideId'],
      );
      final groupName = source['groupName']?.toString();

      if (sessionId != null) {
        fallbackPayload['sessionId'] = sessionId;
      }
      if (rideId != null) {
        fallbackPayload['rideId'] = rideId;
      }
      if (groupName != null && groupName.trim().isNotEmpty) {
        fallbackPayload['groupName'] = groupName.trim();
      }

      return fallbackPayload.isEmpty ? null : jsonEncode(fallbackPayload);
    }

    return NotificationDto(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      // Backend uses 'body', not 'message'
      message: json['body'] ?? json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      type: json['type']?.toString(),
      relatedId: parseNullableInt(
        json['relatedId'] ?? json['sessionId'] ?? json['voiceSessionId'],
      ),
      // Backend uses 'actorId' and nested 'actor' object
      senderId: json['actorId'] ?? json['senderId'],
      senderUsername: json['actor']?['username'] ?? json['senderUsername'],
      senderProfileImage:
          json['actor']?['profilePictureUrl'] ?? json['senderProfileImage'],
      dataJson: normalizeDataJson(json),
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
      dataJson: dataJson,
    );
  }
}
