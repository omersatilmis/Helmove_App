class MessageEndpoints {
  static const String base = '/api/Message';

  // Sending & conversation
  static const String send = '$base/send';
  static String conversation(int otherUserId) =>
      '$base/conversation/$otherUserId';
  static String deleteConversation(int otherUserId) =>
      '$base/conversation/$otherUserId';
  static const String conversations = '$base/conversations';

  // Actions
  static const String markAsRead = '$base/mark-as-read';
  static String markConversationAsRead(int otherUserId) =>
      '$base/mark-conversation-as-read/$otherUserId';

  static String edit(int messageId) => '$base/edit/$messageId';
  static String delete(int messageId) => '$base/delete/$messageId';

  // Stats & Info
  static const String unreadCount = '$base/unread-count';
  static String unreadCountWithUser(int otherUserId) =>
      '$base/unread-count/$otherUserId';
  static const String stats = '$base/stats';

  // Search
  static const String search = '$base/search';
  static const String searchConversations = '$base/search-conversations';

  // Typing
  static const String typingIndicator = '$base/typing-indicator';
}
