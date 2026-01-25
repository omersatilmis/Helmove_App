import '../repositories/message_repository.dart';

class DeleteMessageUseCase {
  final MessageRepository repository;

  DeleteMessageUseCase(this.repository);

  Future<void> call(int messageId) async {
    return await repository.deleteMessage(messageId);
  }
}
