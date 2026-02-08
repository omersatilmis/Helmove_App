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
  final bool isOtherUserTyping;

  const ChatLoaded({
    required this.messages,
    this.isSending = false,
    required this.otherUserId,
    this.isOtherUserTyping = false,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? isSending,
    int? otherUserId,
    bool? isOtherUserTyping,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      otherUserId: otherUserId ?? this.otherUserId,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
    );
  }

  @override
  List<Object> get props => [
    messages,
    isSending,
    otherUserId,
    isOtherUserTyping,
  ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
