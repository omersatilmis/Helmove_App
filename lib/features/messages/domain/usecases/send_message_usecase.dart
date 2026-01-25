import '../../domain/entities/message.dart';
import '../repositories/message_repository.dart';

class SendMessageUseCase {
  final MessageRepository repository;

  SendMessageUseCase(this.repository);

  Future<Message> call({
    required int receiverId,
    required String content,
    int? type,
    String? attachmentUrl,
    LocationData? locationData,
  }) async {
    return await repository.sendMessage(
      receiverId: receiverId,
      content: content,
      type: type,
      attachmentUrl: attachmentUrl,
      locationData: locationData,
    );
  }
}
