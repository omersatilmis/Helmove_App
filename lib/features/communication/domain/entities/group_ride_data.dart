class GroupRideData {
  final int? id;
  final String groupName;
  final int maxParticipants;
  final int currentParticipants;
  final String sessionDuration;
  final String privacy;
  final String destination;
  final String ridingStyle;

  GroupRideData({
    this.id,
    required this.groupName,
    required this.maxParticipants,
    this.currentParticipants = 1,
    this.sessionDuration = "00:00",
    required this.privacy,
    required this.destination,
    required this.ridingStyle,
  });

  GroupRideData copyWith({
    int? id,
    String? groupName,
    int? maxParticipants,
    int? currentParticipants,
    String? sessionDuration,
    String? privacy,
    String? destination,
    String? ridingStyle,
  }) {
    return GroupRideData(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      privacy: privacy ?? this.privacy,
      destination: destination ?? this.destination,
      ridingStyle: ridingStyle ?? this.ridingStyle,
    );
  }
}
