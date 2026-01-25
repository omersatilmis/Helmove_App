import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.type,
    required super.isRead,
    required super.sentAt,
    super.readAt,
    super.attachmentUrl,
    LocationDataModel? super.locationData,
    required super.isEdited,
    super.editedAt,
    super.senderUsername,
    super.senderName,
    super.senderProfilePicture,
    required super.isMine,
    super.timeAgo,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      senderId: json['senderId'] ?? 0,
      receiverId: json['receiverId'] ?? 0,
      content: json['content'] ?? '',
      type: json['type'] ?? 0,
      isRead: json['isRead'] ?? false,
      sentAt: DateTime.parse(json['sentAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      attachmentUrl: json['attachmentUrl'],
      locationData: json['locationData'] != null
          ? LocationDataModel.fromJson(json['locationData'])
          : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      senderUsername: json['senderUsername'],
      senderName: json['senderName'],
      senderProfilePicture: json['senderProfilePicture'],
      isMine: json['isMine'] ?? false,
      timeAgo: json['timeAgo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'isRead': isRead,
      'sentAt': sentAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'locationData': (locationData as LocationDataModel?)?.toJson(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'senderUsername': senderUsername,
      'senderName': senderName,
      'senderProfilePicture': senderProfilePicture,
      'isMine': isMine,
      'timeAgo': timeAgo,
    };
  }
}

class LocationDataModel extends LocationData {
  const LocationDataModel({
    required super.latitude,
    required super.longitude,
    super.address,
  });

  factory LocationDataModel.fromJson(Map<String, dynamic> json) {
    return LocationDataModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude, 'address': address};
  }
}
