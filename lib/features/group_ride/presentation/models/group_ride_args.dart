class GroupRideArgs {
  final int rideId;
  final int? voiceSessionId;
  final String groupName;
  final int? maxParticipants;
  final int? currentParticipants;
  final String? destination;
  final String? ridingStyle;
  final String? privacy;
  final String? sessionDuration;

  const GroupRideArgs({
    required this.rideId,
    this.voiceSessionId,
    required this.groupName,
    this.maxParticipants,
    this.currentParticipants,
    this.destination,
    this.ridingStyle,
    this.privacy,
    this.sessionDuration,
  });

  factory GroupRideArgs.fromMap(Map<String, dynamic> map) {
    return GroupRideArgs(
      rideId: map['id'] ?? map['rideId'] ?? 0,
      voiceSessionId: map['voiceSessionId'],
      groupName: map['groupName'] ?? map['title'] ?? 'Bilinmeyen Grup',
      maxParticipants: map['maxParticipants'],
      currentParticipants: map['currentParticipants'],
      destination: map['destination'],
      ridingStyle: map['ridingStyle'],
      privacy: map['privacy'],
      sessionDuration: map['sessionDuration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': rideId,
      'voiceSessionId': voiceSessionId,
      'groupName': groupName,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'destination': destination,
      'ridingStyle': ridingStyle,
      'privacy': privacy,
      'sessionDuration': sessionDuration,
    };
  }
}
