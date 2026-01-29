import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/text_styles.dart';
import '../bloc/conversations/conversations_bloc.dart';
import '../bloc/conversations/conversations_event.dart';
import '../bloc/conversations/conversations_state.dart';
import 'package:moto_comm_app_1/features/friendship/presentation/pages/pick_friend_page.dart';
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
          // Yeni sohbet başlatma sayfası (Kişi Seçimi)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PickFriendPage()),
          ).then((_) {
            // Döndüğümüzde listeyi yenileyelim (belki sohbet başlatıldı)
            if (context.mounted) {
              context.read<ConversationsBloc>().add(RefreshConversations());
            }
          });
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
              expandedHeight: 60.0,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surfaceTint,
              scrolledUnderElevation: 2,
              elevation: 0,
              centerTitle: false,
              title: Text(
                'Sohbetler',
                style: AppTextStyles.h2.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () {},
                  tooltip: 'Camera',
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () {},
                  tooltip: 'Search',
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () {},
                  tooltip: 'Options',
                ),
              ],
            ),

            // 2. CONVERSATION LIST
            BlocBuilder<ConversationsBloc, ConversationsState>(
              builder: (context, state) {
                if (state is ConversationsLoading) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  );
                } else if (state is ConversationsError) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: Center(
                        child: Text(
                          'Hata: ${state.message}',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                  );
                } else if (state is ConversationsLoaded) {
                  if (state.conversations.isEmpty) {
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No messages yet',
                                style: AppTextStyles.h3.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start chatting with your moto friends!',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    otherUserId: conversation.userId,
                                    firstName: conversation.firstName ?? '',
                                    lastName: conversation.lastName ?? '',
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // AVATAR
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    backgroundImage:
                                        conversation.profilePictureUrl != null
                                        ? NetworkImage(
                                            conversation.profilePictureUrl!,
                                          )
                                        : null,
                                    child:
                                        conversation.profilePictureUrl == null
                                        ? Text(
                                            (conversation.username.isNotEmpty
                                                    ? conversation.username[0]
                                                    : "?")
                                                .toUpperCase(),
                                            style: AppTextStyles.h3.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),

                                  // CONTENT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // TOP ROW: Name + Time
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                conversation.firstName !=
                                                            null &&
                                                        conversation.lastName !=
                                                            null
                                                    ? '${conversation.firstName} ${conversation.lastName}'
                                                    : conversation.username,
                                                style: AppTextStyles.bodyLarge
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (lastMessageTime != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: Text(
                                                  _formatDate(lastMessageTime),
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                        color: isUnread
                                                            ? theme
                                                                  .colorScheme
                                                                  .primary
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        fontWeight: isUnread
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                        fontSize: 12,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // BOTTOM ROW: Message + Badge
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                conversation
                                                        .lastMessage
                                                        ?.content ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      fontSize: 14,
                                                      fontWeight: isUnread
                                                          ? FontWeight.w500
                                                          : FontWeight.normal,
                                                      color: isUnread
                                                          ? theme
                                                                .colorScheme
                                                                .onSurface
                                                          : theme
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                            if (isUnread)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 22,
                                                      minHeight: 22,
                                                    ),
                                                child: Center(
                                                  child: Text(
                                                    conversation.unreadCount > 9
                                                        ? '9+'
                                                        : conversation
                                                              .unreadCount
                                                              .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // SEPARATOR
                          Divider(
                            height: 1,
                            indent:
                                72 +
                                16, // Avatar (56) + Gap (16) + Padding (Left 16) approx
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
