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
    int? attachmentDurationSeconds,
    List<int>? attachmentWaveform,
    LocationData? locationData,
  }) async {
    return await repository.sendMessage(
      receiverId: receiverId,
      content: content,
      type: type,
      attachmentUrl: attachmentUrl,
      attachmentDurationSeconds: attachmentDurationSeconds,
      attachmentWaveform: attachmentWaveform,
      locationData: locationData,
    );
  }
}
