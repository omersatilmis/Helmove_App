import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/delete_message_usecase.dart';
import '../../../domain/usecases/edit_message_usecase.dart';
import '../../../domain/usecases/get_conversation_messages_usecase.dart';
import '../../../domain/usecases/send_message_usecase.dart';
import '../../../domain/usecases/mark_conversation_as_read_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../../../../core/services/message_signalr_service.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationMessagesUseCase getMessages;
  final SendMessageUseCase sendMessage;
  final EditMessageUseCase editMessage;
  final DeleteMessageUseCase deleteMessage;
  final MarkConversationAsReadUseCase markConversationAsRead;
  final MessageSignalRService messageSignalRService;

  ChatBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.editMessage,
    required this.deleteMessage,
    required this.markConversationAsRead,
    required this.messageSignalRService,
  }) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<ReceiveMessageEvent>(_onReceiveMessage);

    // Set up SignalR listener
    messageSignalRService.setOnReceiveDirectMessage((messageData) {
      if (!isClosed) {
        // Map dynamic data to MessageEntity
        try {
          // Assuming messageData matches MessageModel.fromJson structure or is close enough
          // Since we don't have the model here easily without heavy imports,
          // we might need to parse it. Ideally use MessageModel.fromJson(messageData)
          // But strict architecture says Entity in Bloc.
          // For now, let's assume we can map it.
          // Actually better to handle this via Event
          add(ReceiveMessageEvent(messageData));
        } catch (e) {
          print("Error parsing signalr message: $e");
        }
      }
    });
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
    // Initialize SignalR when chat opens
    messageSignalRService.init();

    emit(ChatLoading());
    try {
      final messages = await getMessages(otherUserId: event.otherUserId);
      // Ensure messages are sorted descending (newest first) for reversed list
      messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      emit(ChatLoaded(messages: messages, otherUserId: event.otherUserId));
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
        emit(
          currentState.copyWith(messages: updatedMessages, isSending: false),
        );
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      add(LoadMessages(currentState.otherUserId));
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
        emit(currentState.copyWith(messages: updatedMessages));
      } catch (e) {
        // Handle error
      }
    }
  }
}
