class ApiEndpoints {
  static const String posts = '/api/posts';

  static const String createPost = posts;
  static const String feed = '$posts/feed';
  static String userPosts(int userId) => '$posts/user/$userId';
  static String deletePost(int id) => '$posts/$id';
  static String likePost(int id) => '$posts/$id/like';
}
