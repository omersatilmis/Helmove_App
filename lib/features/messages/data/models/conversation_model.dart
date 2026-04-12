import 'package:helmove/core/network/network_module.dart';
import '../../domain/entities/conversation.dart';
import 'message_model.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.userId,
    required super.username,
    super.firstName,
    super.lastName,
    super.profilePictureUrl,
    required super.isOnline,
    super.lastSeen,
    MessageModel? super.lastMessage,
    required super.unreadCount,
    super.lastActivity,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      profilePictureUrl: NetworkModule.resolveImageUrl(json['profilePictureUrl']?.toString()),
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastMessage': (lastMessage as MessageModel?)?.toJson(),
      'unreadCount': unreadCount,
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }
}
