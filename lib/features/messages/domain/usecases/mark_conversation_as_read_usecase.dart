import '../repositories/message_repository.dart';

class MarkConversationAsReadUseCase {
  final MessageRepository repository;

  MarkConversationAsReadUseCase(this.repository);

  Future<void> call(int otherUserId) async {
    return await repository.markConversationAsRead(otherUserId);
  }
}
