import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/text_styles.dart';
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays == 1) {
      return "Dün";
    } else {
      return "${date.day}/${date.month}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Arkadaş listesine yönlendir veya yeni sohbet dialogu aç
          // Şimdilik arkadaş sayfasına yönlendirelim veya boş bırakalım
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Yeni sohbet başlatmak için Arkadaşlar sayfasına gidin.",
              ),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.message_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ConversationsBloc>().add(RefreshConversations());
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. MODERN SLIVER APP BAR
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 110.0,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surface,
              scrolledUnderElevation: 2,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                title: Text(
                  'Mesajlar',
                  style: AppTextStyles.h2.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                centerTitle: false,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () {
                    // Arama özelliği
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () {},
                ),
              ],
            ),

            // 2. CONVERSATION LIST
            BlocBuilder<ConversationsBloc, ConversationsState>(
              builder: (context, state) {
                if (state is ConversationsLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is ConversationsError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Hata: ${state.message}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  );
                } else if (state is ConversationsLoaded) {
                  if (state.conversations.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 80,
                              color: theme.colorScheme.outline.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz mesajınız yok',
                              style: AppTextStyles.h3.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Arkadaşlarınızla sohbet başlatın!',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final conversation = state.conversations[index];
                      final bool isUnread = conversation.unreadCount > 0;
                      final lastMessageTime = conversation.lastMessage?.sentAt;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            // AVATAR
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              backgroundImage:
                                  conversation.profilePictureUrl != null
                                  ? NetworkImage(
                                      conversation.profilePictureUrl!,
                                    )
                                  : null,
                              child: conversation.profilePictureUrl == null
                                  ? Text(
                                      (conversation.username.isNotEmpty
                                              ? conversation.username[0]
                                              : "?")
                                          .toUpperCase(),
                                      style: AppTextStyles.h3.copyWith(
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    )
                                  : null,
                            ),
                            // İSİM
                            title: Text(
                              conversation.firstName != null &&
                                      conversation.lastName != null
                                  ? '${conversation.firstName} ${conversation.lastName}'
                                  : conversation.username,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            // SON MESAJ
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                conversation.lastMessage?.content ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isUnread
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            // SAĞ TARAF (ZAMAN & BADGE)
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (lastMessageTime != null)
                                  Text(
                                    _formatDate(lastMessageTime),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isUnread
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: isUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                if (isUnread)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 22,
                                      minHeight: 22,
                                    ),
                                    child: Center(
                                      child: Text(
                                        conversation.unreadCount > 9
                                            ? '9+'
                                            : conversation.unreadCount
                                                  .toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    otherUserId: conversation.userId,
                                    username: conversation.username,
                                  ),
                                ),
                              ).then((_) {
                                if (context.mounted) {
                                  context.read<ConversationsBloc>().add(
                                    RefreshConversations(),
                                  );
                                }
                              });
                            },
                          ),
                          // SEPARATOR (WhatsApp style inset)
                          Divider(
                            height: 1,
                            indent: 84, // Avatar + padding
                            endIndent: 0,
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.3,
                            ),
                          ),
                        ],
                      );
                    }, childCount: state.conversations.length),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}
