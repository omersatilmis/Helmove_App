import 'package:equatable/equatable.dart';

class UserPresenceModel extends Equatable {
  final int userId;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserPresenceModel({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  UserPresenceModel copyWith({bool? isOnline, DateTime? lastSeen}) {
    return UserPresenceModel(
      userId: userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  factory UserPresenceModel.fromMap(Map<String, dynamic> map) {
    return UserPresenceModel(
      userId: (map['userId'] is int)
          ? map['userId'] as int
          : int.tryParse(map['userId'].toString()) ?? 0,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.tryParse(map['lastSeen'].toString())?.toLocal()
          : null,
    );
  }

  factory UserPresenceModel.offline(int userId) {
    return UserPresenceModel(
      userId: userId,
      isOnline: false,
      lastSeen: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, isOnline, lastSeen];
}
