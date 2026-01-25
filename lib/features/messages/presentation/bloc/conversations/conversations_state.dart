import 'package:equatable/equatable.dart';
import '../../../domain/entities/conversation.dart';

abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object> get props => [];
}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {}

class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  final int unreadCount;

  const ConversationsLoaded({
    required this.conversations,
    required this.unreadCount,
  });

  @override
  List<Object> get props => [conversations, unreadCount];
}

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError(this.message);

  @override
  List<Object> get props => [message];
}
