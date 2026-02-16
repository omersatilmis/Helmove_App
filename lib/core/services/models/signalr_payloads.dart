class CallRequestPayload {
  final String callerId;
  final String? callerDisplayName;
  final int? callId;

  CallRequestPayload({
    required this.callerId,
    this.callerDisplayName,
    this.callId,
  });

  factory CallRequestPayload.fromMap(Map<String, dynamic> map) {
    return CallRequestPayload(
      callerId: map['callerId'] ?? '',
      callerDisplayName: map['callerDisplayName'],
      callId: map['callId'],
    );
  }
}

class CallAcceptedPayload {
  final String actorId;
  final String? targetUserId;

  CallAcceptedPayload({required this.actorId, this.targetUserId});

  String get acceptedByUserId => actorId;
}

class CallRejectedPayload {
  final String actorId;
  final String? targetUserId;
  final String? reason;

  CallRejectedPayload({
    required this.actorId,
    this.targetUserId,
    this.reason,
  });

  String get rejectedByUserId => actorId;
}

class CallEndedPayload {
  final String actorId;
  final String? targetUserId;
  final String? reason;

  CallEndedPayload({required this.actorId, this.targetUserId, this.reason});

  String get endedByUserId => actorId;
}

class LiveKitTokenPayload {
  final String actorId;
  final String token;
  final String url;
  final String? roomName;

  LiveKitTokenPayload({
    required this.actorId,
    required this.token,
    required this.url,
    this.roomName,
  });

  factory LiveKitTokenPayload.fromMap(Map<String, dynamic> map) {
    final actorId = _readString(map, const [
      'actorId',
      'ActorId',
      'issuedBy',
      'IssuedBy',
      'fromUserId',
      'FromUserId',
      'userId',
      'UserId',
    ]);

    final token = _readString(map, const ['token', 'Token']) ?? '';
    final url = _readString(map, const ['url', 'Url']) ?? '';

    return LiveKitTokenPayload(
      actorId: actorId ?? 'system',
      token: token,
      url: url,
      roomName: _readString(map, const ['roomName', 'RoomName']),
    );
  }
}

class IceCandidatePayload {
  final String fromUserId;
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  IceCandidatePayload({
    required this.fromUserId,
    required this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });
}

class SdpPayload {
  final String userId; // Sender of the SDP
  final String sdp;

  SdpPayload({required this.userId, required this.sdp});
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null || value is Map || value is List) continue;
    final text = value.toString().trim();
    if (text.isEmpty) continue;
    final lower = text.toLowerCase();
    if (lower == 'null' || lower == 'undefined') continue;
    return text;
  }
  return null;
}
