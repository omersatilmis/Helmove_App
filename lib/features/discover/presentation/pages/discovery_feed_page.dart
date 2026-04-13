import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../content/jots/domain/entities/jot_entity.dart';
import '../../../content/jots/presentation/widgets/jot_card_widget.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../../../content/posts/presentation/bloc/posts_bloc.dart';
import '../../../content/posts/presentation/bloc/posts_event.dart';
import '../../../content/posts/presentation/bloc/posts_state.dart';
import '../../../content/posts/presentation/widgets/post_card.dart';
import '../../../interaction/presentation/widgets/comments_sheet.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/discover_event.dart';
import '../bloc/discover_state.dart';

class DiscoveryFeedPage extends StatefulWidget {
  final List<PostEntity> initialPosts;
  final int initialIndex;

  const DiscoveryFeedPage({
    super.key,
    required this.initialPosts,
    required this.initialIndex,
  });

  @override
  State<DiscoveryFeedPage> createState() => _DiscoveryFeedPageState();
}

class _DiscoveryFeedPageState extends State<DiscoveryFeedPage>
    with SingleTickerProviderStateMixin {
  AnimationController? _swipeController;
  Animation<double>? _swipeAnimation;

  late final ScrollController _scrollController;
  late List<PostEntity> _reorderedPosts;

  double _horizontalDragOffset = 0;
  bool _canDragBack = false;
  bool _horizontalIntentLocked = false;
  double _accumulatedDx = 0;
  double _accumulatedDy = 0;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _reorderedPosts = _buildReorderedList(
      widget.initialPosts,
      widget.initialIndex,
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _swipeController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<PostEntity> _buildReorderedList(List<PostEntity> posts, int tappedIndex) {
    if (posts.isEmpty || tappedIndex < 0 || tappedIndex >= posts.length) {
      return posts;
    }

    final tappedPost = posts[tappedIndex];
    final rest = <PostEntity>[
      ...posts.sublist(tappedIndex + 1),
      ...posts.sublist(0, tappedIndex),
    ];
    return [tappedPost, ...rest];
  }

  List<PostEntity> _buildDisplayPosts(List<PostEntity> latestContent) {
    if (latestContent.isEmpty) {
      return const [];
    }

    final postsById = {for (final post in latestContent) post.id: post};
    final usedIds = <int>{};
    final merged = <PostEntity>[];

    for (final reorderedPost in _reorderedPosts) {
      final latest = postsById[reorderedPost.id];
      if (latest != null) {
        merged.add(latest);
        usedIds.add(reorderedPost.id);
      }
    }

    for (final post in latestContent) {
      if (!usedIds.contains(post.id)) {
        merged.add(post);
      }
    }

    return merged;
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<DiscoverBloc>().add(const LoadDiscoveryContent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _animateHorizontalOffsetTo(
    double target, {
    required bool popOnComplete,
  }) {
    final controller = _swipeController;
    if (controller == null) return;

    controller.stop();
    _swipeAnimation = Tween<double>(
      begin: _horizontalDragOffset,
      end: target,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    )
      ..addListener(() {
        if (!mounted) return;
        setState(() {
          _horizontalDragOffset = _swipeAnimation!.value;
        });
      });

    controller
      ..reset()
      ..forward().whenComplete(() {
        if (popOnComplete && mounted) {
          Navigator.of(context).maybePop();
        }
      });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_canDragBack) return;

    _accumulatedDx += details.delta.dx.abs();
    _accumulatedDy += details.delta.dy.abs();

    if (!_horizontalIntentLocked) {
      final movedEnough = (_accumulatedDx + _accumulatedDy) > 8;
      if (!movedEnough) return;

      // Dikey kaydÄ±rma baskÄ±nsa gesture'Ä± listeye bÄ±rak.
      if (_accumulatedDy > _accumulatedDx) {
        _canDragBack = false;
        return;
      }

      _horizontalIntentLocked = true;
    }

    final delta = details.delta.dx;
    final screenWidth = MediaQuery.of(context).size.width;

    _swipeController?.stop();
    setState(() {
      _horizontalDragOffset = (_horizontalDragOffset + delta).clamp(
        0.0,
        screenWidth,
      );
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    // Daha akÄ±cÄ± kullanÄ±m iÃ§in baÅŸlangÄ±cÄ± ekrana sabitlemiyoruz.
    // Yatay niyet tespit edilirse aktifleÅŸiyor.
    _canDragBack = true;
    _horizontalIntentLocked = false;
    _accumulatedDx = 0;
    _accumulatedDy = 0;
  }

  void _onHorizontalDragEnd(DragEndDetails details, double screenWidth) {
    if (!_canDragBack) {
      _horizontalIntentLocked = false;
      _accumulatedDx = 0;
      _accumulatedDy = 0;
      return;
    }
    _canDragBack = false;
    _horizontalIntentLocked = false;
    _accumulatedDx = 0;
    _accumulatedDy = 0;

    final draggedEnough = _horizontalDragOffset > screenWidth * 0.22;
    final fastSwipeRight = details.velocity.pixelsPerSecond.dx > 750;

    if (draggedEnough || fastSwipeRight) {
      _animateHorizontalOffsetTo(screenWidth, popOnComplete: true);
      return;
    }

    _animateHorizontalOffsetTo(0, popOnComplete: false);
  }

  JotEntity _postToJot(PostEntity post) {
    return JotEntity(
      id: post.id,
      userId: post.userId,
      type: JotType.text,
      text: post.text,
      mediaUrl: post.mediaUrl,
      thumbnailUrl: post.thumbnailUrl,
      visibility: JotVisibility.public,
      createdAt: post.createdAt,
      username: post.username,
      firstName: post.userFirstName,
      lastName: post.userLastName,
      userProfilePictureUrl: post.userProfileImage,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      isLiked: post.isLiked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = (_horizontalDragOffset / screenWidth).clamp(0.0, 1.0);
    final opacity = (1 - (progress * 0.08)).clamp(
      0.92,
      1.0,
    );
    final scale = (1 - (progress * 0.035)).clamp(0.965, 1.0);
    final cornerRadius = (progress * 20).clamp(0.0, 20.0);
    final shadowOpacity = (progress * 0.16).clamp(0.0, 0.16);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Geri',
        ),
        title: const Text('Kesfet'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: (details) =>
            _onHorizontalDragEnd(details, screenWidth),
        child: SafeArea(
          child: Stack(
            children: [
              // Altta kalan katman: swipe sÄ±rasÄ±nda hoÅŸ bir derinlik efekti verir.
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                        theme.colorScheme.surfaceContainerHighest,
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(_horizontalDragOffset, 0),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: opacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(cornerRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: shadowOpacity),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: BlocBuilder<DiscoverBloc, DiscoverState>(
                builder: (context, discoverState) {
                  List<PostEntity> displayPosts = _reorderedPosts;
                  bool hasReachedMax = false;

                  if (discoverState is DiscoverDiscoveryLoaded) {
                    hasReachedMax = discoverState.hasReachedMax;
                    displayPosts = _buildDisplayPosts(discoverState.content);
                  }

                  return BlocBuilder<PostsBloc, PostsState>(
                    builder: (context, postsState) {
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: hasReachedMax
                            ? displayPosts.length
                            : displayPosts.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= displayPosts.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          }

                          final post = displayPosts[index];

                          if (post.type == 0) {
                            final jot = _postToJot(post);
                            return JotCardWidget(
                              jot: jot,
                              currentUserId: postsState.currentUserId,
                              onLike: () {
                              context.read<DiscoverBloc>().add(
                                ToggleDiscoverPostLikeEvent(post.id),
                              );
                            },
                            onDelete: () {
                              context.read<PostsBloc>().add(DeletePostEvent(post.id));
                              context.read<DiscoverBloc>().add(
                                LocalDeleteDiscoverPostEvent(post.id),
                              );
                            },
                            onComment: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CommentsSheet(
                                    contentId: post.id,
                                    onCommentCountDelta: (delta) {
                                      context.read<DiscoverBloc>().add(
                                        AdjustDiscoverPostCommentCountEvent(
                                          postId: post.id,
                                          delta: delta,
                                        ),
                                      );
                                      context.read<PostsBloc>().add(
                                        AdjustPostCommentCountEvent(
                                          postId: post.id,
                                          delta: delta,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          }

                          return PostCardModern(
                            post: post,
                            currentUserId: postsState.currentUserId,
                            onLike: () {
                              context.read<DiscoverBloc>().add(
                                ToggleDiscoverPostLikeEvent(post.id),
                              );
                            },
                            onDelete: () {
                              context.read<PostsBloc>().add(DeletePostEvent(post.id));
                              context.read<DiscoverBloc>().add(
                                LocalDeleteDiscoverPostEvent(post.id),
                              );
                            },
                            onComment: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => CommentsSheet(
                                  contentId: post.id,
                                  onCommentCountDelta: (delta) {
                                    context.read<DiscoverBloc>().add(
                                      AdjustDiscoverPostCommentCountEvent(
                                        postId: post.id,
                                        delta: delta,
                                      ),
                                    );
                                    context.read<PostsBloc>().add(
                                      AdjustPostCommentCountEvent(
                                        postId: post.id,
                                        delta: delta,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            onShare: () {},
                            onReport: () {},
                          );
                        },
                      );
                    },
                  );
                },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




