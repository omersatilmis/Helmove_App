class GroupRideData {
  final String groupName;
  final int maxParticipants;
  final int currentParticipants;
  final String sessionDuration;
  final String privacy;
  final String destination;
  final String ridingStyle;

  GroupRideData({
    required this.groupName,
    required this.maxParticipants,
    this.currentParticipants = 1,
    this.sessionDuration = "00:00",
    required this.privacy,
    required this.destination,
    required this.ridingStyle,
  });
}
