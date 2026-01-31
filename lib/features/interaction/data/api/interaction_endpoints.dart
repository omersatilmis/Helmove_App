class InteractionEndpoints {
  static const String likes = '/api/likes';
  static const String comments = '/api/comments';

  static String likeContent(int contentId) => '$likes/$contentId';
  static String unlikeContent(int contentId) => '$likes/$contentId'; // DELETE

  static String getComments(int contentId) => '$comments/$contentId';
  static String addComment(int contentId) => '$comments/$contentId';
  static String deleteComment(int commentId) => '$comments/$commentId';
}
