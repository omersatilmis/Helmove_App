import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  Future<Message> sendMessage({
    required int receiverId,
    required String content,
    int? type,
    String? attachmentUrl,
    int? attachmentDurationSeconds,
    List<int>? attachmentWaveform,
    LocationData? locationData,
  });

  Future<List<Message>> getConversation({
    required int otherUserId,
    int page = 1,
    int pageSize = 50,
  });

  Future<void> deleteConversation(int otherUserId);

  Future<List<Conversation>> getConversations();

  Future<void> markAsRead(List<int> messageIds);

  Future<void> markConversationAsRead(int otherUserId);

  Future<Message> editMessage(int messageId, String newContent);

  Future<void> deleteMessage(int messageId);

  Future<int> getUnreadCount();

  Future<int> getUnreadCountWithUser(int otherUserId);

  // Future<void> sendTypingIndicator(int receiverId, bool isTyping);
  // Omitted typing indicator for now to focus on core features, but can be added.
}
