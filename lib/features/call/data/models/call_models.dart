import '../../domain/entities/call_entities.dart';
import '../../../../core/network/network_module.dart';

class CallRequestModel extends CallRequestEntity {
  CallRequestModel({
    required super.targetUserId,
    required super.callType,
    super.notes,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      // Backend swagger schema: targetUserId string bekliyor.
      'targetUserId': targetUserId.toString(),
      'callType': callType,
    };
    if (notes != null && notes!.trim().isNotEmpty) {
      json['notes'] = notes;
    }
    return json;
  }
}

class CallResponseModel extends CallResponseEntity {
  CallResponseModel({
    required super.callId,
    required super.callerId,
    required super.targetUserId,
    required super.status,
    required super.createdAt,
    super.callerDisplayName,
    super.callerProfileImageUrl,
  });

  factory CallResponseModel.fromJson(Map<String, dynamic> json) {
    final source = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : json;

    int readInt(List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value is int) return value;
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    String readString(List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value != null) return value.toString();
      }
      return '';
    }

    String? readCallerDisplayName() {
      final direct = readString([
        'callerDisplayName',
        'CallerDisplayName',
        'callerName',
        'CallerName',
        'displayName',
        'DisplayName',
      ]);
      if (direct.trim().isNotEmpty) return direct.trim();

      final callerRaw = source['caller'];
      if (callerRaw is Map) {
        final caller = Map<String, dynamic>.from(callerRaw);
        final first = (caller['firstName'] ?? '').toString().trim();
        final last = (caller['lastName'] ?? '').toString().trim();
        final full = '$first $last'.trim();
        if (full.isNotEmpty) return full;

        final username = (caller['username'] ?? '').toString().trim();
        if (username.isNotEmpty) return username;
      }
      return null;
    }

    String? readCallerProfileImageUrl() {
      final direct = readString([
        'callerProfileImageUrl',
        'CallerProfileImageUrl',
        'callerProfilePictureUrl',
        'CallerProfilePictureUrl',
        'profilePictureUrl',
        'ProfilePictureUrl',
        'avatarUrl',
        'AvatarUrl',
      ]);
      if (direct.trim().isNotEmpty) {
        return NetworkModule.resolveImageUrl(direct.trim());
      }

      final callerRaw = source['caller'];
      if (callerRaw is Map) {
        final caller = Map<String, dynamic>.from(callerRaw);
        final profile = (caller['profilePictureUrl'] ??
                caller['profileImageUrl'] ??
                caller['avatarUrl'])
            ?.toString()
            .trim();
        if (profile != null && profile.isNotEmpty) {
          return NetworkModule.resolveImageUrl(profile);
        }
      }
      return null;
    }

    DateTime readDate(List<String> keys) {
      for (final key in keys) {
        final value = source[key];
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return DateTime.now();
    }

    return CallResponseModel(
      callId: readInt(['callId', 'CallId', 'id', 'Id']),
      callerId: readInt(['callerId', 'CallerId']),
      targetUserId: readInt(['targetUserId', 'TargetUserId']),
      status: readString(['status', 'Status']),
      createdAt: readDate(['createdAt', 'CreatedAt']),
      callerDisplayName: readCallerDisplayName(),
      callerProfileImageUrl: readCallerProfileImageUrl(),
    );
  }
}

class OnlineUsersModel extends OnlineUsersEntity {
  OnlineUsersModel({required super.onlineUsers, required super.totalCount});

  factory OnlineUsersModel.fromJson(Map<String, dynamic> json) {
    final source = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : json;

    final users =
        (source['onlineUsers'] ??
                source['OnlineUsers'] ??
                source['users'] ??
                source['Users'])
            as List<dynamic>?;

    final totalRaw =
        source['totalCount'] ??
        source['TotalCount'] ??
        source['count'] ??
        source['Count'];

    return OnlineUsersModel(
      onlineUsers: List<String>.from(users ?? const []),
      totalCount: totalRaw is int
          ? totalRaw
          : int.tryParse(totalRaw?.toString() ?? '0') ?? 0,
    );
  }
}
