import 'dart:async';
import 'dart:io';
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
import '../../../../media/data/api/media_api.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetConversationMessagesUseCase getMessages;
  final SendMessageUseCase sendMessage;
  final EditMessageUseCase editMessage;
  final DeleteMessageUseCase deleteMessage;
  final MarkConversationAsReadUseCase markConversationAsRead;
  final MessageSignalRService messageSignalRService;
  final MediaApi mediaApi;

  Timer? _typingTimer;
  StreamSubscription<List<int>>? _messagesReadSubscription;
  StreamSubscription<dynamic>? _messageEditedSubscription;
  StreamSubscription<int>? _messageDeletedSubscription;
  StreamSubscription<dynamic>? _userStatusChangedSubscription;

  ChatBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.editMessage,
    required this.deleteMessage,
    required this.markConversationAsRead,
    required this.messageSignalRService,
    required this.mediaApi,
  }) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<SendImageAttachmentEvent>(_onSendImageAttachment);
    on<SendVoiceMessageEvent>(_onSendVoiceMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<MessageEditedReceived>(_onMessageEditedReceived);
    on<MessageDeletedReceived>(_onMessageDeletedReceived);
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
    on<OtherUserTypingReceived>(_onOtherUserTypingReceived);
    on<RefreshMessagesReadStatus>(_onRefreshMessagesReadStatus);
    on<OtherUserPresenceChanged>(_onOtherUserPresenceChanged);

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

    // Set up SignalR Message Edited listener
    _messageEditedSubscription = messageSignalRService.onMessageEdited.listen((
      messageData,
    ) {
      if (!isClosed) {
        add(MessageEditedReceived(messageData));
      }
    });

    // Set up SignalR Message Deleted listener
    _messageDeletedSubscription = messageSignalRService.onMessageDeleted.listen((
      messageId,
    ) {
      if (!isClosed) {
        add(MessageDeletedReceived(messageId));
      }
    });

    // Set up SignalR Presence listener
    _userStatusChangedSubscription =
        messageSignalRService.onUserStatusChanged.listen((presence) {
      if (!isClosed) {
        final currentState = state;
        if (currentState is ChatLoaded &&
            currentState.otherUserId == presence.userId) {
          add(
            OtherUserPresenceChanged(
              isOnline: presence.isOnline,
              lastSeen: presence.lastSeen,
            ),
          );
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
      emit(
        ChatLoaded(
          messages: messages,
          otherUserId: event.otherUserId,
          isOtherUserOnline: event.initialIsOnline,
          otherUserLastSeen: event.initialLastSeen,
        ),
      );
    } catch (e) {
      emit(_mapChatError(e));
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
        emit(_mapChatError(e));
      }
    }
  }

  Future<void> _onSendImageAttachment(
    SendImageAttachmentEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    emit(currentState.copyWith(isSending: true));
    try {
      final url = await mediaApi.uploadImage(File(event.filePath));
      final caption = event.caption?.trim() ?? '';
      final newMessage = await sendMessage(
        receiverId: event.receiverId,
        content: caption.isEmpty ? '📷 Fotoğraf' : caption,
        type: 1,
        attachmentUrl: url,
      );
      final latestState = state;
      if (latestState is ChatLoaded) {
        final updatedMessages = List.of(latestState.messages)
          ..insert(0, newMessage);
        emit(latestState.copyWith(messages: updatedMessages, isSending: false));
      }
    } catch (e) {
      final latestState = state;
      if (latestState is ChatLoaded) {
        emit(latestState.copyWith(isSending: false));
      }
      emit(_mapChatError(e));
    }
  }

  Future<void> _onSendVoiceMessage(
    SendVoiceMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    emit(currentState.copyWith(isSending: true));
    try {
      final url = await mediaApi.uploadAudio(File(event.filePath));
      final newMessage = await sendMessage(
        receiverId: event.receiverId,
        content: '🎤 Sesli mesaj',
        type: 2,
        attachmentUrl: url,
        attachmentDurationSeconds: event.durationSeconds,
      );
      // Local file cleanup after successful upload
      try {
        await File(event.filePath).delete();
      } catch (_) {}

      final latestState = state;
      if (latestState is ChatLoaded) {
        final updatedMessages = List.of(latestState.messages)
          ..insert(0, newMessage);
        emit(latestState.copyWith(messages: updatedMessages, isSending: false));
      }
    } catch (e) {
      final latestState = state;
      if (latestState is ChatLoaded) {
        emit(latestState.copyWith(isSending: false));
      }
      emit(_mapChatError(e));
    }
  }

  ChatError _mapChatError(Object error) {
    final raw = error.toString().toLowerCase();

    final isFriendshipRestriction =
        raw.contains('arkadas') ||
        raw.contains('arkadaş') ||
        raw.contains('friend') ||
        raw.contains('not friends') ||
        raw.contains('friendship') ||
        raw.contains('forbidden') ||
        raw.contains('403');

    if (isFriendshipRestriction) {
      return const ChatError(
        '',
        type: ChatErrorType.friendshipRequired,
      );
    }

    return ChatError(
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim(),
    );
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
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        final editedMessage = await editMessage(event.messageId, event.newContent);
        
        final updatedMessages = currentState.messages.map((m) {
          if (m.id == event.messageId) {
            return editedMessage;
          }
          return m;
        }).toList();

        emit(currentState.copyWith(messages: updatedMessages));
      } catch (e) {
        // Handle error if needed
      }
    }
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

  Future<void> _onMessageEditedReceived(
    MessageEditedReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        if (event.messageData is Map<String, dynamic>) {
          final editedMessage = MessageModel.fromJson(
            event.messageData as Map<String, dynamic>,
          );

          final updatedMessages = currentState.messages.map((m) {
            if (m.id == editedMessage.id) {
              return editedMessage;
            }
            return m;
          }).toList();

          emit(currentState.copyWith(messages: updatedMessages));
        }
      } catch (_) {}
    }
  }

  Future<void> _onMessageDeletedReceived(
    MessageDeletedReceived event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = currentState.messages
          .where((m) => m.id != event.messageId)
          .toList();
      emit(currentState.copyWith(messages: updatedMessages));
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

  Future<void> _onOtherUserPresenceChanged(
    OtherUserPresenceChanged event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(
        currentState.copyWith(
          isOtherUserOnline: event.isOnline,
          otherUserLastSeen: event.lastSeen,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    _messagesReadSubscription?.cancel();
    _messageEditedSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _userStatusChangedSubscription?.cancel();
    return super.close();
  }
}
