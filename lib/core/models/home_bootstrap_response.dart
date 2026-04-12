import '../../features/content/posts/data/models/post_model.dart';
import '../../features/content/posts/domain/entities/post_entity.dart';
import '../network/network_module.dart';
import 'pagination_metadata.dart';

class HomeBootstrapResponse {
  final HomeBootstrapUser? user;
  final int unreadMessageCount;
  final int unreadNotificationCount;
  final HomeBootstrapFeed feed;

  const HomeBootstrapResponse({
    required this.user,
    required this.unreadMessageCount,
    required this.unreadNotificationCount,
    required this.feed,
  });

  factory HomeBootstrapResponse.fromJson(
    Map<String, dynamic> json, {
    int fallbackLimit = 10,
  }) {
    final userMap = _toMap(json['user']);
    final feedMap = _toMap(json['feed']) ?? const <String, dynamic>{};

    return HomeBootstrapResponse(
      user: userMap == null ? null : HomeBootstrapUser.fromJson(userMap),
      unreadMessageCount: _readInt([
        json['unreadMessageCount'],
        json['unreadMessages'],
        json['messageUnreadCount'],
      ]),
      unreadNotificationCount: _readInt([
        json['unreadNotificationCount'],
        json['unreadNotifications'],
        json['notificationUnreadCount'],
      ]),
      feed: HomeBootstrapFeed.fromJson(feedMap, fallbackLimit: fallbackLimit),
    );
  }

  static Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  static int _readInt(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }
}

class HomeBootstrapUser {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String? profilePictureUrl;

  const HomeBootstrapUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.profilePictureUrl,
  });

  factory HomeBootstrapUser.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value) {
      if (value == null) return '';
      return value.toString().trim();
    }

    final picture = readString(
      NetworkModule.resolveImageUrl(
            (json['profilePictureUrl'] ?? json['profileImageUrl'])
                ?.toString(),
          ) ??
          '',
    );

    return HomeBootstrapUser(
      id: HomeBootstrapResponse._readInt([json['id']]),
      username: readString(json['username']),
      firstName: readString(json['firstName']),
      lastName: readString(json['lastName']),
      email: readString(json['email']).isEmpty
          ? null
          : readString(json['email']),
      profilePictureUrl: picture.isEmpty ? null : picture,
    );
  }
}

class HomeBootstrapFeed {
  final List<PostEntity> items;
  final PaginationMetadata meta;

  const HomeBootstrapFeed({required this.items, required this.meta});

  bool get hasNextPage => meta.hasNextPage;
  int get limit {
    if (meta.totalPages <= 0) {
      return items.length;
    }
    final computed = (meta.totalCount / meta.totalPages).ceil();
    return computed <= 0 ? items.length : computed;
  }

  factory HomeBootstrapFeed.fromJson(
    Map<String, dynamic> json, {
    int fallbackLimit = 10,
  }) {
    final rawItems = json['items'] ?? json['data'] ?? json['posts'];
    final items = _parseItems(rawItems);

    final rawMeta = json['meta'];
    final meta = rawMeta is Map
        ? PaginationMetadata.fromJson(Map<String, dynamic>.from(rawMeta))
        : PaginationMetadata(
            totalCount: items.length,
            currentPage: 1,
            totalPages: items.isEmpty ? 1 : 2,
            hasNextPage: items.length >= fallbackLimit,
            hasPreviousPage: false,
          );

    return HomeBootstrapFeed(items: items, meta: meta);
  }

  static List<PostEntity> _parseItems(dynamic rawItems) {
    final list = rawItems is List ? rawItems : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => PostModel.fromJson(Map<String, dynamic>.from(item)))
        .cast<PostEntity>()
        .toList();
  }
}
