import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/message_model.dart';
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
  StreamSubscription<List<int>>? _messagesReadSubscription;

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
    on<RefreshMessagesReadStatus>(_onRefreshMessagesReadStatus);

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

    // Set up SignalR MessagesRead listener
    _messagesReadSubscription = messageSignalRService.onMessagesRead.listen((
      messageIds,
    ) {
      if (!isClosed) {
        add(RefreshMessagesReadStatus(messageIds));
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
      // Try to parse the incoming SignalR message data optimistically
      try {
        if (event.messageData is Map<String, dynamic>) {
          final incomingMessage = MessageModel.fromJson(
            event.messageData as Map<String, dynamic>,
          );

          // Avoid duplicates
          final alreadyExists = currentState.messages.any(
            (m) => m.id == incomingMessage.id,
          );
          if (alreadyExists) return;

          // Only add if this message belongs to the current conversation
          final isFromOtherUser =
              incomingMessage.senderId == currentState.otherUserId;
          final isToOtherUser =
              incomingMessage.receiverId == currentState.otherUserId;

          if (isFromOtherUser || isToOtherUser) {
            final updatedMessages = List.of(currentState.messages)
              ..insert(0, incomingMessage);
            emit(currentState.copyWith(messages: updatedMessages));

            // Auto mark-as-read if the message is from the other user
            // (we're already viewing this chat)
            if (isFromOtherUser) {
              add(MarkAsRead(currentState.otherUserId));
            }
          }
          return;
        }
      } catch (_) {
        // If parsing fails, fall back to a silent reload
      }

      // Fallback: reload without showing loading spinner
      try {
        final messages = await getMessages(
          otherUserId: currentState.otherUserId,
        );
        messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        emit(currentState.copyWith(messages: messages));
        add(MarkAsRead(currentState.otherUserId));
      } catch (_) {
        // Silent error - don't disrupt the UI
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

  Future<void> _onRefreshMessagesReadStatus(
    RefreshMessagesReadStatus event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      if (event.messageIds.isEmpty) return;

      // Update isRead locally for the specified message IDs
      final readIdSet = event.messageIds.toSet();
      final updatedMessages = currentState.messages.map((msg) {
        if (readIdSet.contains(msg.id) && !msg.isRead) {
          return msg.copyWith(isRead: true, readAt: DateTime.now());
        }
        return msg;
      }).toList();

      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    _messagesReadSubscription?.cancel();
    return super.close();
  }
}
