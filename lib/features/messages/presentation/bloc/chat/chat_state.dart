import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool isSending;
  final int otherUserId;

  const ChatLoaded({
    required this.messages,
    this.isSending = false,
    required this.otherUserId,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? isSending,
    int? otherUserId,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      otherUserId: otherUserId ?? this.otherUserId,
    );
  }

  @override
  List<Object> get props => [messages, isSending, otherUserId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
