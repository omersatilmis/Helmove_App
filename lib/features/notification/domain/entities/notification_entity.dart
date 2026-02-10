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

  // Helper getters for parsing dataJson safely
  int? get voiceSessionId {
    if (dataJson == null) return null;
    // Simple parsing, assuming dataJson is valid JSON string
    try {
      // Note: In real logic, we should use jsonDecode.
      // But since this is an entity, we keep it simple or use a helper.
      // Better to do this parsing in Model or use logic here.
      // Let's use a regex or check if we can import dart:convert.
      // Entities usually shouldn't depend on dart:convert but it's part of dart:core essentially.
      // Actually, better to parse keys manually or rely on the fact that dataJson is string.
      final RegExp regExp = RegExp(r'"voiceSessionId":\s*(\d+)');
      final match = regExp.firstMatch(dataJson!);
      return match != null ? int.parse(match.group(1)!) : null;
    } catch (_) {
      return null;
    }
  }

  int? get groupRideId {
    if (dataJson == null) return null;
    try {
      final RegExp regExp = RegExp(r'"groupRideId":\s*(\d+)');
      final match = regExp.firstMatch(dataJson!);
      return match != null ? int.parse(match.group(1)!) : null;
    } catch (_) {
      return null;
    }
  }

  String? get groupName {
    if (dataJson == null) return null;
    try {
      final RegExp regExp = RegExp(r'"groupName":\s*"([^"]+)"');
      final match = regExp.firstMatch(dataJson!);
      return match?.group(1);
    } catch (_) {
      return null;
    }
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
