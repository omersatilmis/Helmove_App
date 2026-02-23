import 'dart:convert';

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
  final String? dataJson;

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
    this.dataJson,
  });

  Map<String, dynamic>? get _parsedDataJson {
    final raw = dataJson;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  int? _readIntFromData(List<String> keys) {
    final data = _parsedDataJson;
    if (data == null) {
      return null;
    }

    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }

    return null;
  }

  String? _readStringFromData(List<String> keys) {
    final data = _parsedDataJson;
    if (data == null) {
      return null;
    }

    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  // Canonical keys: sessionId and rideId.
  // Legacy aliases are still read for backward compatibility.
  int? get sessionId =>
      _readIntFromData(const ['sessionId', 'voiceSessionId']) ?? relatedId;

  int? get rideId => _readIntFromData(const ['rideId', 'groupRideId']);

  // Backward-compatible aliases used by existing UI code.
  int? get voiceSessionId => sessionId;
  int? get groupRideId => rideId;

  String? get groupName {
    return _readStringFromData(const ['groupName', 'rideTitle', 'title']);
  }

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
    dataJson,
  ];
}
