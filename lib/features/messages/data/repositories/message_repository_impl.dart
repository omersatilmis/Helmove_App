import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_data_source.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl(this.remoteDataSource);

  @override
  Future<Message> sendMessage({
    required int receiverId,
    required String content,
    int? type,
    String? attachmentUrl,
    LocationData? locationData,
  }) async {
    return await remoteDataSource.sendMessage(
      receiverId: receiverId,
      content: content,
      type: type,
      attachmentUrl: attachmentUrl,
      locationData: locationData,
    );
  }

  @override
  Future<List<Message>> getConversation({
    required int otherUserId,
    int page = 1,
    int pageSize = 50,
  }) async {
    return await remoteDataSource.getConversation(
      otherUserId: otherUserId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<void> deleteConversation(int otherUserId) async {
    await remoteDataSource.deleteConversation(otherUserId);
  }

  @override
  Future<List<Conversation>> getConversations() async {
    return await remoteDataSource.getConversations();
  }

  @override
  Future<void> markAsRead(List<int> messageIds) async {
    await remoteDataSource.markAsRead(messageIds);
  }

  @override
  Future<void> markConversationAsRead(int otherUserId) async {
    await remoteDataSource.markConversationAsRead(otherUserId);
  }

  @override
  Future<Message> editMessage(int messageId, String newContent) async {
    return await remoteDataSource.editMessage(messageId, newContent);
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await remoteDataSource.deleteMessage(messageId);
  }

  @override
  Future<int> getUnreadCount() async {
    return await remoteDataSource.getUnreadCount();
  }

  @override
  Future<int> getUnreadCountWithUser(int otherUserId) async {
    return await remoteDataSource.getUnreadCountWithUser(otherUserId);
  }
}
