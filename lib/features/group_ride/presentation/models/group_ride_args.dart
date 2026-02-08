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
  final String? description;
  final String? difficulty;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? startLocation;
  final String? endLocation;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final int? organizerId;

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
    this.description,
    this.difficulty,
    this.startDateTime,
    this.endDateTime,
    this.startLocation,
    this.endLocation,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.organizerId,
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
      description: map['description'],
      difficulty: map['difficulty'],
      startDateTime: map['startDateTime'] != null
          ? DateTime.parse(map['startDateTime'])
          : null,
      endDateTime: map['endDateTime'] != null
          ? DateTime.parse(map['endDateTime'])
          : null,
      startLocation: map['startLocation'],
      endLocation: map['endLocation'],
      startLatitude: map['startLatitude']?.toDouble(),
      startLongitude: map['startLongitude']?.toDouble(),
      endLatitude: map['endLatitude']?.toDouble(),
      endLongitude: map['endLongitude']?.toDouble(),
      organizerId: map['organizerId'],
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
      'description': description,
      'difficulty': difficulty,
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'organizerId': organizerId,
    };
  }
}
