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

class SearchConversationsEvent extends ConversationsEvent {
  final String query;

  const SearchConversationsEvent(this.query);

  @override
  List<Object> get props => [query];
}

class NewMessageReceivedEvent extends ConversationsEvent {
  final dynamic messageData;

  const NewMessageReceivedEvent(this.messageData);

  @override
  List<Object> get props => [messageData];
}
