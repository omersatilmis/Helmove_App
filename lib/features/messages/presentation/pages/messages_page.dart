import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/unread_count_badge.dart';
import '../../../../core/widgets/app_input_field.dart';
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

class ConversationsView extends StatefulWidget {
  const ConversationsView({super.key});

  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text;
      if (query != _searchQuery) {
        _searchQuery = query;
        context.read<ConversationsBloc>().add(SearchConversationsEvent(query));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        _searchQuery = '';
        context.read<ConversationsBloc>().add(const SearchConversationsEvent(''));
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color itemTileColor =
        isDark ? const Color(0xFF1C1917) : Colors.white;


    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: _isSearchMode
              ? AppInputField(
                  controller: _searchController,
                  type: AppInputType.discover,
                  size: AppInputSize.small,
                  hint: 'Sohbet ara...',
                  textInputAction: TextInputAction.search,
                  showFocusBorder: false,
                  radius: 12,
                )
              : Text(
                  'Sohbetler',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearchMode ? Icons.close_rounded : Icons.search_rounded,
              ),
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {},
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: theme.dividerColor.withValues(alpha: 0.05),
              height: 1.0,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PickFriendPage()),
            ).then((_) {
              if (context.mounted) {
                context.read<ConversationsBloc>().add(RefreshConversations());
              }
            });
          },
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          child: const Icon(Icons.add_comment_rounded),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<ConversationsBloc>().add(RefreshConversations());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            BlocBuilder<ConversationsBloc, ConversationsState>(
              builder: (context, state) {
                if (state is ConversationsLoading) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                } else if (state is ConversationsLoaded) {
                  final filteredConversations = state.filteredConversations;

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
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Henuz mesaj yok',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Arkadaslarinla sohbet etmeye basla!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (filteredConversations.isEmpty &&
                      _searchQuery.trim().isNotEmpty) {
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sonuc bulunamadi',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
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
                      final conversation = filteredConversations[index];
                      final bool isUnread = conversation.unreadCount > 0;
                      final lastMessageTime = conversation.lastMessage?.sentAt;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: itemTileColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    otherUserId: conversation.userId,
                                    firstName: conversation.firstName ?? '',
                                    lastName: conversation.lastName ?? '',
                                    username: conversation.username,
                                    profileImageUrl:
                                        conversation.profilePictureUrl,
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
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        backgroundImage:
                                            conversation.profilePictureUrl !=
                                                    null
                                                ? CachedNetworkImageProvider(
                                                    conversation
                                                        .profilePictureUrl!,
                                                  )
                                                : null,
                                        child:
                                            conversation.profilePictureUrl ==
                                                    null
                                                ? Text(
                                                    (conversation.username
                                                                .isNotEmpty
                                                            ? conversation
                                                                .username[0]
                                                            : '?')
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20,
                                                    ),
                                                  )
                                                : null,
                                      ),
                                      if (conversation.isOnline)
                                        Positioned(
                                          right: 2,
                                          bottom: 2,
                                          child: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF22C55E),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: itemTileColor,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                conversation.firstName != null &&
                                                        conversation.lastName !=
                                                            null
                                                    ? '${conversation.firstName} ${conversation.lastName}'
                                                    : conversation.username,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight: isUnread
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                                      color: isUnread
                                                          ? colorScheme
                                                              .onSurface
                                                          : colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.9,
                                                              ),
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (lastMessageTime != null)
                                              Text(
                                                _formatDate(lastMessageTime),
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: isUnread
                                                          ? colorScheme.primary
                                                          : colorScheme
                                                              .onSurfaceVariant,
                                                      fontWeight: isUnread
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                conversation.lastMessage
                                                        ?.content ??
                                                    '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight: isUnread
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color: isUnread
                                                          ? colorScheme
                                                              .onSurface
                                                          : colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                            if (isUnread)
                                              UnreadCountBadge.message(
                                                count:
                                                    conversation.unreadCount,
                                                scheme: colorScheme,
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
                        ),
                      );
                    }, childCount: filteredConversations.length),
                  );
                } else if (state is ConversationsError) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: Center(
                        child: Text(
                          'Hata: ${state.message}',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ),
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

