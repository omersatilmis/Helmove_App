import '../entities/message.dart';
import '../repositories/message_repository.dart';

class GetConversationMessagesUseCase {
  final MessageRepository repository;

  GetConversationMessagesUseCase(this.repository);

  Future<List<Message>> call({
    required int otherUserId,
    int page = 1,
    int pageSize = 50,
  }) async {
    return await repository.getConversation(
      otherUserId: otherUserId,
      page: page,
      pageSize: pageSize,
    );
  }
}
