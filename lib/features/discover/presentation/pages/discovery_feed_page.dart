import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../../../content/posts/presentation/widgets/post_card.dart';
import '../../../content/posts/presentation/bloc/posts_bloc.dart';
import '../../../content/posts/presentation/bloc/posts_event.dart';
import '../../../content/posts/presentation/bloc/posts_state.dart';
import '../../../content/jots/domain/entities/jot_entity.dart';
import '../../../content/jots/presentation/widgets/jot_card_widget.dart';
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

class _DiscoveryFeedPageState extends State<DiscoveryFeedPage> {
  late final ScrollController _scrollController;
  late List<PostEntity> _reorderedPosts;

  @override
  void initState() {
    super.initState();
    _reorderedPosts = _buildReorderedList(
      widget.initialPosts,
      widget.initialIndex,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  List<PostEntity> _buildReorderedList(
    List<PostEntity> posts,
    int tappedIndex,
  ) {
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// PostEntity → JotEntity dönüşümü (type=0 ise Jot)
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

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DiscoverBloc, DiscoverState>(
          builder: (context, discoverState) {
            List<PostEntity> displayPosts = _reorderedPosts;
            bool hasReachedMax = false;

            if (discoverState is DiscoverDiscoveryLoaded) {
              final allBlocPosts = discoverState.content;
              hasReachedMax = discoverState.hasReachedMax;

              final existingIds = _reorderedPosts.map((p) => p.id).toSet();
              final newPosts = allBlocPosts
                  .where((p) => !existingIds.contains(p.id))
                  .toList();

              if (newPosts.isNotEmpty) {
                displayPosts = [..._reorderedPosts, ...newPosts];
              }
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

                    // type=0 → Jot, type=1 → Post, type=2 → Reel
                    if (post.type == 0) {
                      final jot = _postToJot(post);
                      return JotCardWidget(
                        jot: jot,
                        currentUserId: postsState.currentUserId,
                        onLike: () {
                          context.read<PostsBloc>().add(LikePostEvent(post.id));
                          context.read<DiscoverBloc>().add(LocalLikeDiscoverPostEvent(post.id));
                        },
                        onDelete: () {
                          context.read<PostsBloc>().add(
                            DeletePostEvent(post.id),
                          );
                          context.read<DiscoverBloc>().add(LocalDeleteDiscoverPostEvent(post.id));
                        },
                        onComment: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                CommentsSheet(contentId: post.id),
                          );
                        },
                      );
                    }

                    // Post veya Reel → PostCardModern
                    return PostCardModern(
                      post: post,
                      currentUserId: postsState.currentUserId,
                      onLike: () {
                        context.read<PostsBloc>().add(LikePostEvent(post.id));
                        context.read<DiscoverBloc>().add(LocalLikeDiscoverPostEvent(post.id));
                      },
                      onDelete: () {
                        context.read<PostsBloc>().add(DeletePostEvent(post.id));
                        context.read<DiscoverBloc>().add(LocalDeleteDiscoverPostEvent(post.id));
                      },
                      onComment: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              CommentsSheet(contentId: post.id),
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
    );
  }
}
