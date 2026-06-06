import 'package:dio/dio.dart';
import '../api/message_endpoints.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../../domain/entities/message.dart'; // For LocationData

abstract class MessageRemoteDataSource {
  Future<MessageModel> sendMessage({
    required int receiverId,
    required String content,
    int? type,
    String? attachmentUrl,
    int? attachmentDurationSeconds,
    List<int>? attachmentWaveform,
    LocationData? locationData,
  });

  Future<List<MessageModel>> getConversation({
    required int otherUserId,
    int page = 1,
    int pageSize = 50,
  });

  Future<void> deleteConversation(int otherUserId);

  Future<List<ConversationModel>> getConversations();

  Future<void> markAsRead(List<int> messageIds);

  Future<void> markConversationAsRead(int otherUserId);

  Future<MessageModel> editMessage(int messageId, String newContent);

  Future<void> deleteMessage(int messageId);

  Future<int> getUnreadCount();

  Future<int> getUnreadCountWithUser(int otherUserId);
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final Dio dio;

  MessageRemoteDataSourceImpl(this.dio);

  @override
  Future<MessageModel> sendMessage({
    required int receiverId,
    required String content,
    int? type,
    String? attachmentUrl,
    int? attachmentDurationSeconds,
    List<int>? attachmentWaveform,
    LocationData? locationData,
  }) async {
    final body = {
      'receiverId': receiverId,
      'content': content,
      'type': type ?? 0,
      'attachmentUrl': attachmentUrl,
      'attachmentDurationSeconds': attachmentDurationSeconds,
      'attachmentWaveform': attachmentWaveform,
      'locationData': locationData != null
          ? {
              'latitude': locationData.latitude,
              'longitude': locationData.longitude,
              'address': locationData.address,
            }
          : null,
    };

    final response = await dio.post(MessageEndpoints.send, data: body);

    return MessageModel.fromJson(_extractData(response));
  }

  @override
  Future<List<MessageModel>> getConversation({
    required int otherUserId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final url = MessageEndpoints.conversation(otherUserId);

      final response = await dio.get(
        url,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      final data = _extractData(response);
      final List list = data is List ? data : [];
      return list.map((e) => MessageModel.fromJson(e)).toList();
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(int otherUserId) async {
    await dio.delete(MessageEndpoints.deleteConversation(otherUserId));
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await dio.get(MessageEndpoints.conversations);

    final data = _extractData(response);
    final List list = data is List ? data : [];
    return list.map((e) => ConversationModel.fromJson(e)).toList();
  }

  @override
  Future<void> markAsRead(List<int> messageIds) async {
    await dio.post(
      MessageEndpoints.markAsRead,
      data: {'messageIds': messageIds},
    );
  }

  @override
  Future<void> markConversationAsRead(int otherUserId) async {
    await dio.post(MessageEndpoints.markConversationAsRead(otherUserId));
  }

  @override
  Future<MessageModel> editMessage(int messageId, String newContent) async {
    final response = await dio.put(
      MessageEndpoints.edit(messageId),
      data: {'content': newContent},
    );

    return MessageModel.fromJson(_extractData(response));
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await dio.delete(MessageEndpoints.delete(messageId));
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await dio.get(MessageEndpoints.unreadCount);

    return _extractData(response) as int;
  }

  @override
  Future<int> getUnreadCountWithUser(int otherUserId) async {
    final response = await dio.get(
      MessageEndpoints.unreadCountWithUser(otherUserId),
    );

    return _extractData(response) as int;
  }

  dynamic _extractData(Response response) {
    var data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }
}
