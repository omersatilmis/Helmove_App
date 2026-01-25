import '../repositories/message_repository.dart';

class MarkAsReadUseCase {
  final MessageRepository repository;

  MarkAsReadUseCase(this.repository);

  Future<void> call(List<int> messageIds) async {
    return await repository.markAsRead(messageIds);
  }
}
