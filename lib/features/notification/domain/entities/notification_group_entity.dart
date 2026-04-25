import 'dart:convert';
import 'package:equatable/equatable.dart';

// type int değerleri: 0=General, 1=FriendRequest, 2=Follow, 3=Like,
// 4=Comment, 5=VoiceSessionInvite, 9=GroupRideInvite, 14=DirectMessage
class NotificationGroupEntity extends Equatable {
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

  const NotificationGroupEntity({
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

  Map<String, dynamic>? get parsedDataJson {
    final raw = latestDataJson;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return null;
  }

  int? _readInt(List<String> keys) {
    final data = parsedDataJson;
    if (data == null) return null;
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      if (v is int) return v;
      final p = int.tryParse(v.toString());
      if (p != null) return p;
    }
    return null;
  }

  int? get sessionId => _readInt(const ['sessionId', 'voiceSessionId']);
  int? get rideId    => _readInt(const ['rideId', 'groupRideId']);
  int? get relatedId => _readInt(const ['contentId', 'relatedId']);

  String? get groupName {
    final data = parsedDataJson;
    if (data == null) return null;
    return (data['groupName'] ?? data['rideTitle'] ?? data['title'])?.toString();
  }

  String get typeString {
    switch (type) {
      case 0:  return 'general';
      case 1:  return 'friendrequest';
      case 2:  return 'follow';
      case 3:  return 'like';
      case 4:  return 'comment';
      case 5:  return 'voicesessioninvite';
      case 9:  return 'grouprideinvite';
      case 14: return 'directmessage';
      default: return 'general';
    }
  }

  NotificationGroupEntity copyWithRead() => NotificationGroupEntity(
        actorId: actorId,
        actorUsername: actorUsername,
        actorProfilePicture: actorProfilePicture,
        type: type,
        count: count,
        latestNotificationId: latestNotificationId,
        latestTitle: latestTitle,
        latestBody: latestBody,
        latestDataJson: latestDataJson,
        isRead: true,
        lastActivityAt: lastActivityAt,
      );

  @override
  List<Object?> get props => [
        actorId,
        actorUsername,
        actorProfilePicture,
        type,
        count,
        latestNotificationId,
        latestTitle,
        latestBody,
        latestDataJson,
        isRead,
        lastActivityAt,
      ];
}
