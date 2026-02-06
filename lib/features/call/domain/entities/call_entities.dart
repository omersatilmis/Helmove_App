class CallRequestEntity {
  final String targetUserId;
  final String callType;
  final String? notes;

  CallRequestEntity({
    required this.targetUserId,
    required this.callType,
    this.notes,
  });
}

class CallResponseEntity {
  final int callId;
  final String callerId;
  final String targetUserId;
  final String status;
  final DateTime createdAt;

  CallResponseEntity({
    required this.callId,
    required this.callerId,
    required this.targetUserId,
    required this.status,
    required this.createdAt,
  });
}

class OnlineUsersEntity {
  final List<String> onlineUsers;
  final int totalCount;

  OnlineUsersEntity({required this.onlineUsers, required this.totalCount});
}
