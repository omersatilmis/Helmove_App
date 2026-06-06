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
  final int? attachmentDurationSeconds;
  final List<int>? attachmentWaveform;
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
    this.attachmentDurationSeconds,
    this.attachmentWaveform,
    this.locationData,
    required this.isEdited,
    this.editedAt,
    this.senderUsername,
    this.senderName,
    this.senderProfilePicture,
    required this.isMine,
    this.timeAgo,
  });

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    int? type,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
    String? attachmentUrl,
    int? attachmentDurationSeconds,
    List<int>? attachmentWaveform,
    LocationData? locationData,
    bool? isEdited,
    DateTime? editedAt,
    String? senderUsername,
    String? senderName,
    String? senderProfilePicture,
    bool? isMine,
    String? timeAgo,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentDurationSeconds:
          attachmentDurationSeconds ?? this.attachmentDurationSeconds,
      attachmentWaveform: attachmentWaveform ?? this.attachmentWaveform,
      locationData: locationData ?? this.locationData,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      senderUsername: senderUsername ?? this.senderUsername,
      senderName: senderName ?? this.senderName,
      senderProfilePicture: senderProfilePicture ?? this.senderProfilePicture,
      isMine: isMine ?? this.isMine,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }

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
    attachmentDurationSeconds,
    attachmentWaveform,
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
