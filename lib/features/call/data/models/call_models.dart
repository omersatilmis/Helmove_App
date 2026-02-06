import '../../domain/entities/call_entities.dart';

class CallRequestModel extends CallRequestEntity {
  CallRequestModel({
    required super.targetUserId,
    required super.callType,
    super.notes,
  });

  Map<String, dynamic> toJson() {
    return {'targetUserId': targetUserId, 'callType': callType, 'notes': notes};
  }
}

class CallResponseModel extends CallResponseEntity {
  CallResponseModel({
    required super.callId,
    required super.callerId,
    required super.targetUserId,
    required super.status,
    required super.createdAt,
  });

  factory CallResponseModel.fromJson(Map<String, dynamic> json) {
    return CallResponseModel(
      callId: json['callId'] ?? 0,
      callerId: json['callerId'] ?? '',
      targetUserId: json['targetUserId'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class OnlineUsersModel extends OnlineUsersEntity {
  OnlineUsersModel({required super.onlineUsers, required super.totalCount});

  factory OnlineUsersModel.fromJson(Map<String, dynamic> json) {
    return OnlineUsersModel(
      onlineUsers: List<String>.from(json['onlineUsers'] ?? []),
      totalCount: json['totalCount'] ?? 0,
    );
  }
}
