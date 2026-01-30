import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/delete_message_usecase.dart';
import '../../../domain/usecases/edit_message_usecase.dart';
import '../../../domain/usecases/get_conversation_messages_usecase.dart';
import '../../../domain/usecases/send_message_usecase.dart';
import '../../../domain/usecases/mark_conversation_as_read_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationMessagesUseCase getMessages;
  final SendMessageUseCase sendMessage;
  final EditMessageUseCase editMessage;
  final DeleteMessageUseCase deleteMessage;
  final MarkConversationAsReadUseCase markConversationAsRead;

  ChatBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.editMessage,
    required this.deleteMessage,
    required this.markConversationAsRead,
  }) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<MarkAsRead>(_onMarkAsRead);
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      await markConversationAsRead(event.otherUserId);
    } catch (e) {
      // Silent error
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final messages = await getMessages(otherUserId: event.otherUserId);
      // Ensure messages are sorted descending (newest first) for reversed list
      messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isSending: true));
      try {
        final newMessage = await sendMessage(
          receiverId: event.receiverId,
          content: event.content,
        );
        final updatedMessages = List.of(currentState.messages)
          ..insert(0, newMessage);
        emit(ChatLoaded(messages: updatedMessages, isSending: false));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    // TODO: Implement edit logic locally optimistically or refresh
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        await deleteMessage(event.messageId);
        final updatedMessages = currentState.messages
            .where((m) => m.id != event.messageId)
            .toList();
        emit(ChatLoaded(messages: updatedMessages));
      } catch (e) {
        // Handle error
      }
    }
  }
}
