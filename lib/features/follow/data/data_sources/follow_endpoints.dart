class FollowEndpoints {
  static const String base = '/api/follow';
  
  static String follow(int userId) => '$base/$userId';
  static String unfollow(int userId) => '$base/$userId';
  static String followers(int userId) => '$base/followers/$userId';
  static String following(int userId) => '$base/following/$userId';
  static const String myFollowers = '$base/followers/me';
  static const String myFollowing = '$base/following/me';
  static String block(int userId) => '$base/block/$userId';
  static String unblock(int userId) => '$base/unblock/$userId';
  static const String blocked = '$base/blocked';
}
