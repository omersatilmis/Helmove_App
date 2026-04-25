import '../../domain/entities/notification_group_entity.dart';

class NotificationGroupDto {
  final int? actorId;
  final String? actorUsername;
  final String? actorProfilePicture;
  final int type;
  final int count;
  final int latestNotificationId;
  final String latestTitle;
  final String? latestBody;
  final String? latestDataJson;
  final bool isRead;
  final DateTime lastActivityAt;

  NotificationGroupDto({
    this.actorId,
    this.actorUsername,
    this.actorProfilePicture,
    required this.type,
    required this.count,
    required this.latestNotificationId,
    required this.latestTitle,
    this.latestBody,
    this.latestDataJson,
    required this.isRead,
    required this.lastActivityAt,
  });

  factory NotificationGroupDto.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    int parseInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    return NotificationGroupDto(
      actorId: parseNullableInt(json['actorId']),
      actorUsername: json['actorUsername']?.toString(),
      actorProfilePicture: json['actorProfilePicture']?.toString(),
      type: parseInt(json['type'], 0),
      count: parseInt(json['count'], 1),
      latestNotificationId: parseInt(json['latestNotificationId'], 0),
      latestTitle: json['latestTitle']?.toString() ?? '',
      latestBody: json['latestBody']?.toString(),
      latestDataJson: json['latestDataJson']?.toString(),
      isRead: json['isRead'] == true,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.tryParse(json['lastActivityAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationGroupEntity toEntity() => NotificationGroupEntity(
        actorId: actorId,
        actorUsername: actorUsername,
        actorProfilePicture: actorProfilePicture,
        type: type,
        count: count,
        latestNotificationId: latestNotificationId,
        latestTitle: latestTitle,
        latestBody: latestBody,
        latestDataJson: latestDataJson,
        isRead: isRead,
        lastActivityAt: lastActivityAt,
      );
}
