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
