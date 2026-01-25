import '../entities/conversation.dart';
import '../repositories/message_repository.dart';

class GetConversationsUseCase {
  final MessageRepository repository;

  GetConversationsUseCase(this.repository);

  Future<List<Conversation>> call() async {
    return await repository.getConversations();
  }
}
