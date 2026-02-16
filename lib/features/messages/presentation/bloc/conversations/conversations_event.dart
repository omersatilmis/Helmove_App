import 'package:equatable/equatable.dart';

abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object> get props => [];
}

class LoadConversations extends ConversationsEvent {}

class RefreshConversations extends ConversationsEvent {}

class DeleteConversationEvent extends ConversationsEvent {
  final int otherUserId;

  const DeleteConversationEvent(this.otherUserId);

  @override
  List<Object> get props => [otherUserId];
}

class MarkConversationReadEvent extends ConversationsEvent {
  final int otherUserId;

  const MarkConversationReadEvent(this.otherUserId);

  @override
  List<Object> get props => [otherUserId];
}

class SyncConversationsRealtimeEvent extends ConversationsEvent {
  const SyncConversationsRealtimeEvent();
}
