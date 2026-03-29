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

  CallRejectedPayload({required this.actorId, this.targetUserId, this.reason});

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

class RideRealtimePayload {
  final int rideId;
  final int? sessionId;
  final String? eventId;
  final int? version;
  final DateTime? occurredAtUtc;
  final String? eventType;

  const RideRealtimePayload({
    required this.rideId,
    this.sessionId,
    this.eventId,
    this.version,
    this.occurredAtUtc,
    this.eventType,
  });

  factory RideRealtimePayload.fromMap(Map<String, dynamic> map) {
    return RideRealtimePayload(
      // Canonical contract: rideId / sessionId.
      // Legacy aliases are still accepted as a fallback.
      rideId:
          _readCanonicalInt(
            map,
            canonicalKeys: const ['rideId', 'RideId'],
            legacyKeys: const ['groupRideId', 'GroupRideId', 'id', 'Id'],
          ) ??
          0,
      sessionId: _readCanonicalInt(
        map,
        canonicalKeys: const ['sessionId', 'SessionId'],
        legacyKeys: const ['voiceSessionId', 'VoiceSessionId'],
      ),
      eventId: _readString(map, const ['eventId', 'EventId']),
      version: _readInt(map, const ['version', 'Version']),
      occurredAtUtc: _readDateTime(map, const [
        'occurredAtUtc',
        'OccurredAtUtc',
      ]),
      eventType: _readString(map, const ['eventType', 'EventType', 'type']),
    );
  }
}

class VoiceSessionRefreshRealtimePayload {
  final int sessionId;
  final int? rideId;
  final String? eventId;
  final int? version;
  final DateTime? occurredAtUtc;
  final String? eventType;
  final String? reason;

  const VoiceSessionRefreshRealtimePayload({
    required this.sessionId,
    this.rideId,
    this.eventId,
    this.version,
    this.occurredAtUtc,
    this.eventType,
    this.reason,
  });

  factory VoiceSessionRefreshRealtimePayload.fromMap(Map<String, dynamic> map) {
    return VoiceSessionRefreshRealtimePayload(
      // Canonical contract: sessionId / rideId.
      // Legacy aliases are still accepted as a fallback.
      sessionId:
          _readCanonicalInt(
            map,
            canonicalKeys: const ['sessionId', 'SessionId'],
            legacyKeys: const ['voiceSessionId', 'VoiceSessionId', 'id', 'Id'],
          ) ??
          0,
      rideId: _readCanonicalInt(
        map,
        canonicalKeys: const ['rideId', 'RideId'],
        legacyKeys: const ['groupRideId', 'GroupRideId'],
      ),
      eventId: _readString(map, const ['eventId', 'EventId']),
      version: _readInt(map, const ['version', 'Version']),
      occurredAtUtc: _readDateTime(map, const [
        'occurredAtUtc',
        'OccurredAtUtc',
      ]),
      eventType: _readString(map, const ['eventType', 'EventType', 'type']),
      reason: _readString(map, const ['reason', 'Reason']),
    );
  }
}

class VoiceSessionMembershipRealtimePayload {
  final String userId;
  final int sessionId;
  final String? eventId;
  final int? version;
  final DateTime? occurredAtUtc;
  final String? eventType;

  const VoiceSessionMembershipRealtimePayload({
    required this.userId,
    required this.sessionId,
    this.eventId,
    this.version,
    this.occurredAtUtc,
    this.eventType,
  });

  factory VoiceSessionMembershipRealtimePayload.fromMap(
    Map<String, dynamic> map,
  ) {
    return VoiceSessionMembershipRealtimePayload(
      userId:
          _readString(map, const ['userId', 'UserId', 'id', 'Id', 'actorId']) ??
          '',
      // Canonical contract: sessionId.
      // Legacy aliases are still accepted as a fallback.
      sessionId:
          _readCanonicalInt(
            map,
            canonicalKeys: const ['sessionId', 'SessionId'],
            legacyKeys: const ['voiceSessionId', 'VoiceSessionId'],
          ) ??
          0,
      eventId: _readString(map, const ['eventId', 'EventId']),
      version: _readInt(map, const ['version', 'Version']),
      occurredAtUtc: _readDateTime(map, const [
        'occurredAtUtc',
        'OccurredAtUtc',
      ]),
      eventType: _readString(map, const ['eventType', 'EventType', 'type']),
    );
  }
}

class SosAlertPayload {
  final int groupRideId;
  final int senderId;
  final String senderFullName;
  final String senderUsername;
  final String? senderProfilePictureUrl;
  final double latitude;
  final double longitude;
  final DateTime sentAt;

  const SosAlertPayload({
    required this.groupRideId,
    required this.senderId,
    required this.senderFullName,
    required this.senderUsername,
    this.senderProfilePictureUrl,
    required this.latitude,
    required this.longitude,
    required this.sentAt,
  });

  factory SosAlertPayload.fromMap(Map<String, dynamic> map) {
    final groupRideId =
        _readCanonicalInt(
          map,
          canonicalKeys: const ['groupRideId', 'GroupRideId'],
          legacyKeys: const ['rideId', 'RideId'],
        ) ??
        0;
    final senderId =
        _readCanonicalInt(
          map,
          canonicalKeys: const ['senderId', 'SenderId'],
          legacyKeys: const ['actorId', 'ActorId', 'userId', 'UserId'],
        ) ??
        0;
    final latitude = _readDouble(map, const [
      'latitude',
      'Latitude',
      'lat',
      'Lat',
    ]);
    final longitude = _readDouble(map, const [
      'longitude',
      'Longitude',
      'lng',
      'Lng',
    ]);
    final sentAt =
        _readDateTime(map, const ['sentAt', 'SentAt', 'createdAt']) ??
        DateTime.now().toUtc();

    return SosAlertPayload(
      groupRideId: groupRideId,
      senderId: senderId,
      senderFullName:
          _readString(map, const ['senderFullName', 'SenderFullName']) ?? '',
      senderUsername:
          _readString(map, const ['senderUsername', 'SenderUsername']) ?? '',
      senderProfilePictureUrl: _readString(map, const [
        'senderProfilePictureUrl',
        'SenderProfilePictureUrl',
      ]),
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      sentAt: sentAt,
    );
  }

  static SosAlertPayload? tryParse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final payload = SosAlertPayload.fromMap(raw);
      if (payload.isValid) return payload;
      final nested = raw['data'];
      if (nested is Map<String, dynamic>) {
        final nestedPayload = SosAlertPayload.fromMap(nested);
        return nestedPayload.isValid ? nestedPayload : null;
      }
      if (nested is Map) {
        final nestedPayload = SosAlertPayload.fromMap(
          Map<String, dynamic>.from(nested),
        );
        return nestedPayload.isValid ? nestedPayload : null;
      }
      return null;
    }
    if (raw is Map) {
      return tryParse(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  bool get isValid {
    if (groupRideId <= 0 || senderId <= 0) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }
}

DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
  final text = _readString(data, keys);
  if (text == null) return null;
  return DateTime.tryParse(text);
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

int? _readInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null || value is Map || value is List) continue;
    if (value is int) return value;
    final parsed = int.tryParse(value.toString().trim());
    if (parsed != null) return parsed;
  }
  return null;
}

double? _readDouble(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null || value is Map || value is List) continue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value.toString().trim());
    if (parsed != null) return parsed;
  }
  return null;
}

int? _readCanonicalInt(
  Map<String, dynamic> data, {
  required List<String> canonicalKeys,
  List<String> legacyKeys = const [],
}) {
  final canonical = _readInt(data, canonicalKeys);
  if (canonical != null) {
    return canonical;
  }
  if (legacyKeys.isEmpty) {
    return null;
  }
  return _readInt(data, legacyKeys);
}

class ParticipantStatusPayload {
  final int userId;
  final int? phoneBatteryLevel;
  final int? intercomBatteryLevel;
  final int? signalStrength;
  final bool? isRemoteMuted;

  ParticipantStatusPayload({
    required this.userId,
    this.phoneBatteryLevel,
    this.intercomBatteryLevel,
    this.signalStrength,
    this.isRemoteMuted,
  });

  factory ParticipantStatusPayload.fromMap(Map<String, dynamic> map) {
    return ParticipantStatusPayload(
      userId: map['userId'] is int
          ? map['userId']
          : int.tryParse(map['userId'].toString()) ?? 0,
      phoneBatteryLevel: map['phoneBatteryLevel'],
      intercomBatteryLevel: map['intercomBatteryLevel'],
      signalStrength: map['signalStrength'],
      isRemoteMuted: map['isRemoteMuted'] ?? map['IsMuted'],
    );
  }
}

class UserMuteStatePayload {
  final int targetUserId;
  final bool isMuted;
  final int mutedByUserId;

  UserMuteStatePayload({
    required this.targetUserId,
    required this.isMuted,
    required this.mutedByUserId,
  });

  factory UserMuteStatePayload.fromMap(Map<String, dynamic> map) {
    return UserMuteStatePayload(
      targetUserId: map['targetUserId'] is int
          ? map['targetUserId']
          : int.tryParse(map['targetUserId'].toString()) ?? 0,
      isMuted: map['isMuted'] ?? false,
      mutedByUserId: map['mutedByUserId'] is int
          ? map['mutedByUserId']
          : int.tryParse(map['mutedByUserId'].toString()) ?? 0,
    );
  }
}
