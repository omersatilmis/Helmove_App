import '../repositories/message_repository.dart';

class DeleteConversationUseCase {
  final MessageRepository repository;

  DeleteConversationUseCase(this.repository);

  Future<void> call(int otherUserId) async {
    return await repository.deleteConversation(otherUserId);
  }
}
