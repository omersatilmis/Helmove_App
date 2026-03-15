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
  final String searchQuery;

  const ConversationsLoaded({
    required this.conversations,
    required this.unreadCount,
    this.searchQuery = '',
  });

  List<Conversation> get filteredConversations {
    if (searchQuery.trim().isEmpty) return conversations;

    final query = _normalize(searchQuery);
    return conversations.where((conversation) {
      final fullName =
          '${conversation.firstName ?? ''} ${conversation.lastName ?? ''}'.trim();
      final fields = <String>[
        conversation.username,
        fullName,
        conversation.lastMessage?.content ?? '',
      ];
      return fields.any((field) => _normalize(field).contains(query));
    }).toList();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .trim();
  }

  @override
  List<Object> get props => [conversations, unreadCount, searchQuery];

  ConversationsLoaded copyWith({
    List<Conversation>? conversations,
    int? unreadCount,
    String? searchQuery,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      unreadCount: unreadCount ?? this.unreadCount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError(this.message);

  @override
  List<Object> get props => [message];
}
