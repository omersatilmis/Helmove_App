import '../repositories/message_repository.dart';

class GetUnreadCountUseCase {
  final MessageRepository repository;

  GetUnreadCountUseCase(this.repository);

  Future<int> call() async {
    return await repository.getUnreadCount();
  }

  Future<int> withUser(int otherUserId) async {
    return await repository.getUnreadCountWithUser(otherUserId);
  }
}
