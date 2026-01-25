import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final int type;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? readAt;
  final String? attachmentUrl;
  final LocationData? locationData;
  final bool isEdited;
  final DateTime? editedAt;
  final String? senderUsername;
  final String? senderName;
  final String? senderProfilePicture;
  final bool isMine;
  final String? timeAgo;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.isRead,
    required this.sentAt,
    this.readAt,
    this.attachmentUrl,
    this.locationData,
    required this.isEdited,
    this.editedAt,
    this.senderUsername,
    this.senderName,
    this.senderProfilePicture,
    required this.isMine,
    this.timeAgo,
  });

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    type,
    isRead,
    sentAt,
    readAt,
    attachmentUrl,
    locationData,
    isEdited,
    editedAt,
    senderUsername,
    senderName,
    senderProfilePicture,
    isMine,
    timeAgo,
  ];
}

class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}
