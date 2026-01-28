class JotsEndpoints {
  static const String base = '/api/jots';

  /// POST /api/jots
  static const String createJot = base;

  /// GET /api/jots/feed?page=1
  static const String feed = '$base/feed';

  /// GET /api/jots/user/{userId}?page=1
  static String userJots(int userId) => '$base/user/$userId';

  /// DELETE /api/jots/{id}
  static String deleteJot(int id) => '$base/$id';
}
