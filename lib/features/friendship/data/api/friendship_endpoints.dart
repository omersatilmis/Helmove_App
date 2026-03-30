class ApiEndpoints {
  static const String friendship = '/api/Friendship';

  static const String sendFriendRequest = '$friendship/send-request';
  static String acceptFriendRequest(int id) => '$friendship/accept/$id';
  static String rejectFriendRequest(int id) => '$friendship/reject/$id';
  static String cancelSentRequest(int id) => '$friendship/cancel/$id';
  static String removeFriend(int id) => '$friendship/remove/$id';
  static String blockUser(int userId) => '$friendship/block/$userId';
  static String unblockUser(int userId) => '$friendship/unblock/$userId';

  static const String myFriends = '$friendship/my-friends';
  static String friends(int userId) => '$friendship/friends/$userId';
  static const String pendingRequests = '$friendship/pending-requests';
  static const String sentRequests = '$friendship/sent-requests';
  static const String friendshipStats = '$friendship/stats';

  static String areFriends(int userId) => '$friendship/are-friends/$userId';
  static String friendshipStatus(int userId) =>
      '$friendship/friendship-status/$userId';
  static String mutualFriends(int userId) =>
      '$friendship/mutual-friends/$userId';
  static const String searchFriends = '$friendship/search';
}
