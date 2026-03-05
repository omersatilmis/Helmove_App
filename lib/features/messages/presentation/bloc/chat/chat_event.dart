import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadMessages extends ChatEvent {
  final int otherUserId;

  const LoadMessages(this.otherUserId);

  @override
  List<Object> get props => [otherUserId];
}

class SendMessageEvent extends ChatEvent {
  final int receiverId;
  final String content;

  const SendMessageEvent({required this.receiverId, required this.content});

  @override
  List<Object> get props => [receiverId, content];
}

class EditMessageEvent extends ChatEvent {
  final int messageId;
  final String newContent;

  const EditMessageEvent(this.messageId, this.newContent);

  @override
  List<Object> get props => [messageId, newContent];
}

class DeleteMessageEvent extends ChatEvent {
  final int messageId;

  const DeleteMessageEvent(this.messageId);

  @override
  List<Object> get props => [messageId];
}

class MarkAsRead extends ChatEvent {
  final int otherUserId;

  const MarkAsRead(this.otherUserId);

  @override
  List<Object> get props => [otherUserId];
}

class ReceiveMessageEvent extends ChatEvent {
  final dynamic messageData;

  const ReceiveMessageEvent(this.messageData);

  @override
  List<Object> get props => [messageData];
}

class UpdateTypingStatus extends ChatEvent {
  final int targetUserId;
  final bool isTyping;

  const UpdateTypingStatus({
    required this.targetUserId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [targetUserId, isTyping];
}

class OtherUserTypingReceived extends ChatEvent {
  final bool isTyping;

  const OtherUserTypingReceived(this.isTyping);

  @override
  List<Object> get props => [isTyping];
}

class RefreshMessagesReadStatus extends ChatEvent {
  final List<int> messageIds;

  const RefreshMessagesReadStatus(this.messageIds);

  @override
  List<Object> get props => [messageIds];
}
