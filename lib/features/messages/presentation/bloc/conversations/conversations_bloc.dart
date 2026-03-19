import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/message_model.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/usecases/delete_conversation_usecase.dart';
import '../../../domain/usecases/get_conversations_usecase.dart';
import '../../../domain/usecases/get_unread_count_usecase.dart';
import '../../../domain/usecases/mark_conversation_as_read_usecase.dart';
import '../../../../../core/services/message_signalr_service.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversationsUseCase getConversations;
  final DeleteConversationUseCase deleteConversation;
  final MarkConversationAsReadUseCase markConversationAsRead;
  final GetUnreadCountUseCase getUnreadCount;
  final MessageSignalRService messageSignalRService;

  StreamSubscription<dynamic>? _incomingMessageSubscription;
  StreamSubscription<void>? _messagesReadSubscription;

  ConversationsBloc({
    required this.getConversations,
    required this.deleteConversation,
    required this.markConversationAsRead,
    required this.getUnreadCount,
    required this.messageSignalRService,
  }) : super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<DeleteConversationEvent>(_onDeleteConversation);
    on<MarkConversationReadEvent>(_onMarkConversationRead);
    on<SyncConversationsRealtimeEvent>(_onRealtimeSync);
    on<SearchConversationsEvent>(_onSearchConversations);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);

    messageSignalRService.init();
    _incomingMessageSubscription = messageSignalRService.onDirectMessageReceived.listen((message) {
      if (!isClosed) {
        add(NewMessageReceivedEvent(message));
      }
    });
    _messagesReadSubscription = messageSignalRService.onMessagesRead.listen((_) {
      if (!isClosed) {
        // For read status, we might still want to refresh to get updated counts easily
        // Or we could potentially update locally if messageIds are available
        add(const SyncConversationsRealtimeEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _incomingMessageSubscription?.cancel();
    _messagesReadSubscription?.cancel();
    return super.close();
  }

  Future<void> _onRealtimeSync(
    SyncConversationsRealtimeEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    // Optimized: Only refresh if not already loading
    if (state is! ConversationsLoading) {
      add(RefreshConversations());
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading());
    try {
      // Parallel data fetching
      final results = await Future.wait([
        getConversations(),
        getUnreadCount(),
      ]);
      
      emit(
        ConversationsLoaded(
          conversations: results[0] as List<Conversation>,
          unreadCount: results[1] as int,
        ),
      );
    } catch (e) {
      emit(ConversationsError(e.toString()));
    }
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      final results = await Future.wait([
        getConversations(),
        getUnreadCount(),
      ]);

      if (state is ConversationsLoaded) {
        final currentState = state as ConversationsLoaded;
        emit(
          currentState.copyWith(
            conversations: results[0] as List<Conversation>,
            unreadCount: results[1] as int,
          ),
        );
      } else {
        emit(
          ConversationsLoaded(
            conversations: results[0] as List<Conversation>,
            unreadCount: results[1] as int,
          ),
        );
      }
    } catch (e) {
      emit(ConversationsError(e.toString()));
    }
  }

  void _onSearchConversations(
    SearchConversationsEvent event,
    Emitter<ConversationsState> emit,
  ) {
    if (state is ConversationsLoaded) {
      emit((state as ConversationsLoaded).copyWith(searchQuery: event.query));
    }
  }

  Future<void> _onNewMessageReceived(
    NewMessageReceivedEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    if (state is ConversationsLoaded) {
      final currentState = state as ConversationsLoaded;
      
      try {
        if (event.messageData is Map<String, dynamic>) {
          final newMessage = MessageModel.fromJson(event.messageData as Map<String, dynamic>);
          
          // Find if conversation exists
          final otherUserId = newMessage.isMine ? newMessage.receiverId : newMessage.senderId;
          final conversations = List<Conversation>.from(currentState.conversations);
          
          final index = conversations.indexWhere((c) => c.userId == otherUserId);
          
          if (index != -1) {
            final oldConv = conversations[index];
            final updatedConv = oldConv.copyWith(
              lastMessage: newMessage,
              unreadCount: newMessage.isMine ? oldConv.unreadCount : oldConv.unreadCount + 1,
              lastActivity: newMessage.sentAt,
            );
            
            conversations.removeAt(index);
            conversations.insert(0, updatedConv);
            
            emit(currentState.copyWith(
              conversations: conversations,
              unreadCount: newMessage.isMine ? currentState.unreadCount : currentState.unreadCount + 1,
            ));
            return;
          }
        }
      } catch (_) {
        // Fallback to full refresh if parsing or local update fails
      }
      
      add(RefreshConversations());
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversationEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      await deleteConversation(event.otherUserId);
      add(RefreshConversations());
    } catch (e) {
      emit(ConversationsError(e.toString()));
    }
  }

  Future<void> _onMarkConversationRead(
    MarkConversationReadEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      await markConversationAsRead(event.otherUserId);
      add(RefreshConversations());
    } catch (e) {
      // Silently fail or log?
    }
  }
}
