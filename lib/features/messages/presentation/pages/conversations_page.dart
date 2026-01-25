import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../bloc/conversations/conversations_bloc.dart';
import '../bloc/conversations/conversations_event.dart';
import '../bloc/conversations/conversations_state.dart';
import 'chat_page.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ConversationsBloc>()..add(LoadConversations()),
      child: const ConversationsView(),
    );
  }
}

class ConversationsView extends StatelessWidget {
  const ConversationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<ConversationsBloc, ConversationsState>(
        builder: (context, state) {
          if (state is ConversationsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConversationsError) {
            return Center(child: Text('Hata: ${state.message}'));
          } else if (state is ConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return const Center(child: Text('Henüz hiç mesajınız yok.'));
            }
            return ListView.builder(
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: conversation.profilePictureUrl != null
                        ? NetworkImage(conversation.profilePictureUrl!)
                        : null,
                    child: conversation.profilePictureUrl == null
                        ? Text(conversation.username[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    conversation.firstName != null &&
                            conversation.lastName != null
                        ? '${conversation.firstName} ${conversation.lastName}'
                        : conversation.username,
                    style: TextStyle(
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    conversation.lastMessage?.content ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: conversation.unreadCount > 0
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      /*
                      if (conversation.lastMessage != null)
                        Text(
                          _formatDate(conversation.lastMessage!.sentAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      */
                      const SizedBox(height: 4),
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to ChatPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          otherUserId: conversation.userId,
                          username: conversation.username,
                        ),
                      ),
                    ).then((_) {
                      // Refresh when coming back
                      context.read<ConversationsBloc>().add(
                        RefreshConversations(),
                      );
                    });
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /*
  String _formatDate(DateTime date) {
    // Simple date formatting logic
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
  */
}
