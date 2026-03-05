import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/jot_entity.dart';
import '../dto/jot_dto.dart'; // We use JotModel for serialization

class JotFeedCacheSnapshot {
  final List<JotEntity> jots;
  final bool hasNextPage;
  final DateTime cachedAt;
  final String? etag;

  const JotFeedCacheSnapshot({
    required this.jots,
    required this.hasNextPage,
    required this.cachedAt,
    required this.etag,
  });
}

class JotFeedCache {
  static const String _keyPrefix = 'jot_feed_cache_v1';
  static const Duration defaultMaxAge = Duration(days: 7);

  final SharedPreferences _sharedPreferences;

  JotFeedCache(this._sharedPreferences);

  Future<JotFeedCacheSnapshot?> readFirstPage({
    int limit = 10,
    Duration maxAge = defaultMaxAge,
  }) async {
    final raw = _sharedPreferences.getString(_cacheKey(limit));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final map = Map<String, dynamic>.from(decoded);
      final timestampMs = _toInt(map['timestampMs']);
      final hasNextPage = map['hasNextPage'] == true;
      final etagRaw = map['etag'];
      final jotsRaw = map['jots'];
      final jotsList = jotsRaw is List ? jotsRaw : const <dynamic>[];

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      if (DateTime.now().difference(cachedAt) > maxAge) {
        await _sharedPreferences.remove(_cacheKey(limit));
        return null;
      }

      final jots = jotsList
          .whereType<Map>()
          .map((item) => JotModel.fromJson(Map<String, dynamic>.from(item)))
          .cast<JotEntity>()
          .toList();

      return JotFeedCacheSnapshot(
        jots: jots,
        hasNextPage: hasNextPage,
        cachedAt: cachedAt,
        etag: _toNullableString(etagRaw),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeFirstPage({
    required List<JotEntity> jots,
    required bool hasNextPage,
    String? etag,
    int limit = 10,
  }) async {
    try {
      final firstPage = jots.take(limit).toList();
      final payload = {
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
        'hasNextPage': hasNextPage,
        'etag': _toNullableString(etag),
        'jots': firstPage.map((jot) => _jotToJson(jot)).toList(),
      };

      await _sharedPreferences.setString(_cacheKey(limit), jsonEncode(payload));
    } catch (_) {
      // Cache best-effort only.
    }
  }

  Future<void> clear({int limit = 10}) async {
    await _sharedPreferences.remove(_cacheKey(limit));
  }

  String _cacheKey(int limit) => '${_keyPrefix}_$limit';

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  Map<String, dynamic> _jotToJson(JotEntity jot) {
    // We map entity to model data map for consistency
    return {
      'id': jot.id,
      'userId': jot.userId,
      'type': jot.type.index,
      'text': jot.text,
      'mediaUrl': jot.mediaUrl,
      'thumbnailUrl': jot.thumbnailUrl,
      'visibility': jot.visibility.index,
      'createdAt': jot.createdAt?.toIso8601String(),
      'updatedAt': jot.updatedAt?.toIso8601String(),
      'user': {
        'username': jot.username,
        'firstName': jot.firstName,
        'lastName': jot.lastName,
        'profilePictureUrl': jot.userProfilePictureUrl,
        'bikeModel': jot.bikeModel,
      },
      'likeCount': jot.likeCount,
      'commentCount': jot.commentCount,
      'isLiked': jot.isLiked,
    };
  }
}
