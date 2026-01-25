import '../entities/message.dart';
import '../repositories/message_repository.dart';

class EditMessageUseCase {
  final MessageRepository repository;

  EditMessageUseCase(this.repository);

  Future<Message> call(int messageId, String newContent) async {
    return await repository.editMessage(messageId, newContent);
  }
}
