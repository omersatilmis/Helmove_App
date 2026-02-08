import 'dart:async';
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

  Timer? _typingTimer;

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
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
    on<OtherUserTypingReceived>(_onOtherUserTypingReceived);

    // Set up SignalR Direct Message listener
    messageSignalRService.setOnReceiveDirectMessage((messageData) {
      if (!isClosed) {
        add(ReceiveMessageEvent(messageData));
      }
    });

    // Set up SignalR Typing listener
    messageSignalRService.setOnUserTyping((senderId, isTyping) {
      if (!isClosed) {
        final currentState = state;
        if (currentState is ChatLoaded) {
          // Only react if it's the person we are currently chatting with
          if (currentState.otherUserId.toString() == senderId) {
            add(OtherUserTypingReceived(isTyping));
          }
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

  Future<void> _onUpdateTypingStatus(
    UpdateTypingStatus event,
    Emitter<ChatState> emit,
  ) async {
    await messageSignalRService.sendTypingIndicator(
      event.targetUserId,
      event.isTyping,
    );
  }

  Future<void> _onOtherUserTypingReceived(
    OtherUserTypingReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      _typingTimer?.cancel();

      emit(currentState.copyWith(isOtherUserTyping: event.isTyping));

      if (event.isTyping) {
        // Safety timeout: if we don't receive "stop typing" within 5 seconds, clear it
        _typingTimer = Timer(const Duration(seconds: 5), () {
          if (!isClosed) {
            add(const OtherUserTypingReceived(false));
          }
        });
      }
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    return super.close();
  }
}
