import '/core/navigation/base_navigation_args.dart';

class GroupRideArgs extends BaseNavigationArgs {
  final int rideId;
  final int? sessionId;
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
  final bool forceBackToCommunication;

  const GroupRideArgs({
    required this.rideId,
    this.sessionId,
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
    this.forceBackToCommunication = false,
  });

  factory GroupRideArgs.fromMap(Map<String, dynamic> map) {
    return GroupRideArgs(
      rideId: map['id'] ?? map['rideId'] ?? 0,
      sessionId: map['sessionId'] ?? map['voiceSessionId'],
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
      forceBackToCommunication: map['forceBackToCommunication'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': rideId,
      'sessionId': sessionId,
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
      'forceBackToCommunication': forceBackToCommunication,
    };
  }

  @override
  bool get isValid => (rideId > 0) || (sessionId != null && sessionId! > 0);

  @override
  String? get errorMessage => isValid ? null : 'Geçersiz Sürüş veya Oturum ID';

  static GroupRideArgs? fromExtra(Object? extra) {
    if (extra is GroupRideArgs) return extra;
    if (extra is Map<String, dynamic>) {
      // Handle nested 'data' key if present (sometimes used in SignalR or complex maps)
      final data = extra['data'];
      if (data is GroupRideArgs) return data;
      if (data is Map<String, dynamic>) return GroupRideArgs.fromMap(data);
      return GroupRideArgs.fromMap(extra);
    }
    return null;
  }

  factory GroupRideArgs.empty() {
    return const GroupRideArgs(rideId: 0, groupName: '');
  }
}
