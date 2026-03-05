import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/post_entity.dart';
import '../models/post_model.dart';

class PostFeedCacheSnapshot {
  final List<PostEntity> posts;
  final bool hasNextPage;
  final DateTime cachedAt;
  final String? etag;

  const PostFeedCacheSnapshot({
    required this.posts,
    required this.hasNextPage,
    required this.cachedAt,
    required this.etag,
  });
}

class PostFeedCache {
  static const String _keyPrefix = 'home_feed_cache_v1';
  static const Duration defaultMaxAge = Duration(days: 7);

  final SharedPreferences _sharedPreferences;

  PostFeedCache(this._sharedPreferences);

  Future<PostFeedCacheSnapshot?> readFirstPage({
    required int? userId,
    int limit = 10,
    Duration maxAge = defaultMaxAge,
  }) async {
    final raw = _sharedPreferences.getString(_cacheKey(userId, limit));
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
      final postsRaw = map['posts'];
      final postsList = postsRaw is List ? postsRaw : const <dynamic>[];

      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      if (DateTime.now().difference(cachedAt) > maxAge) {
        await _sharedPreferences.remove(_cacheKey(userId, limit));
        return null;
      }

      final posts = postsList
          .whereType<Map>()
          .map((item) => PostModel.fromJson(Map<String, dynamic>.from(item)))
          .cast<PostEntity>()
          .toList();

      return PostFeedCacheSnapshot(
        posts: posts,
        hasNextPage: hasNextPage,
        cachedAt: cachedAt,
        etag: _toNullableString(etagRaw),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeFirstPage({
    required int? userId,
    required List<PostEntity> posts,
    required bool hasNextPage,
    String? etag,
    int limit = 10,
  }) async {
    try {
      final firstPage = posts.take(limit).toList();
      final payload = {
        'timestampMs': DateTime.now().millisecondsSinceEpoch,
        'hasNextPage': hasNextPage,
        'etag': _toNullableString(etag),
        'posts': firstPage.map(_postToJson).toList(),
      };

      await _sharedPreferences.setString(
        _cacheKey(userId, limit),
        jsonEncode(payload),
      );
    } catch (_) {
      // Cache best-effort only.
    }
  }

  Future<void> clearForUser({required int? userId, int limit = 10}) async {
    await _sharedPreferences.remove(_cacheKey(userId, limit));
  }

  String _cacheKey(int? userId, int limit) =>
      '${_keyPrefix}_${userId ?? 0}_$limit';

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

  Map<String, dynamic> _postToJson(PostEntity post) {
    return {
      'id': post.id,
      'type': post.type,
      'text': post.text,
      'mediaUrl': post.mediaUrl,
      'thumbnailUrl': post.thumbnailUrl,
      'visibility': post.visibility,
      'createdAt': post.createdAt.toIso8601String(),
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'isLiked': post.isLiked,
      'user': {
        'id': post.userId,
        'username': post.username,
        'firstName': post.userFirstName,
        'lastName': post.userLastName,
        'profilePictureUrl': post.userProfileImage,
      },
    };
  }
}
