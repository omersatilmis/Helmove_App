import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/delete_conversation_usecase.dart';
import '../../../domain/usecases/get_conversations_usecase.dart';
import '../../../domain/usecases/get_unread_count_usecase.dart';
import '../../../domain/usecases/mark_conversation_as_read_usecase.dart';
import 'conversations_event.dart';
import 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final GetConversationsUseCase getConversations;
  final DeleteConversationUseCase deleteConversation;
  final MarkConversationAsReadUseCase markConversationAsRead;
  final GetUnreadCountUseCase getUnreadCount;

  ConversationsBloc({
    required this.getConversations,
    required this.deleteConversation,
    required this.markConversationAsRead,
    required this.getUnreadCount,
  }) : super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<DeleteConversationEvent>(_onDeleteConversation);
    on<MarkConversationReadEvent>(_onMarkConversationRead);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading());
    try {
      final conversations = await getConversations();
      final unreadCount = await getUnreadCount();
      emit(
        ConversationsLoaded(
          conversations: conversations,
          unreadCount: unreadCount,
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
      final conversations = await getConversations();
      final unreadCount = await getUnreadCount();
      emit(
        ConversationsLoaded(
          conversations: conversations,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      // Refresh error doesn't change state usually, but can show snackbar if handled in UI
      // Keeping previous state if possible, or just re-emitting current loaded state?
      // For simplicity emitting error
      emit(ConversationsError(e.toString()));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversationEvent event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      await deleteConversation(event.otherUserId);
      add(LoadConversations());
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
      add(LoadConversations()); // Reload to update unread status and count
    } catch (e) {
      // Silently fail or log?
    }
  }
}
