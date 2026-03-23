import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../../../content/posts/presentation/widgets/post_card.dart';
import '../../../content/posts/presentation/bloc/posts_bloc.dart';
import '../../../content/posts/presentation/bloc/posts_event.dart';
import '../../../content/posts/presentation/bloc/posts_state.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    // Initial index'e zıplamak için offset hesaplaması (yaklaşık)
    double offset = 0;
    for (int i = 0; i < widget.initialIndex; i++) {
        final post = widget.initialPosts[i];
        offset += (post.mediaUrl != null && post.mediaUrl!.isNotEmpty ? 450 : 250) + 24;
    }
    _scrollController = ScrollController(initialScrollOffset: offset);
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Keşfet"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<DiscoverBloc, DiscoverState>(
        builder: (context, discoverState) {
          final posts = (discoverState is DiscoverDiscoveryLoaded) 
              ? discoverState.content 
              : widget.initialPosts;
          final hasReachedMax = (discoverState is DiscoverDiscoveryLoaded) 
              ? discoverState.hasReachedMax 
              : false;

          return BlocBuilder<PostsBloc, PostsState>(
            builder: (context, postsState) {
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: hasReachedMax ? posts.length : posts.length + 1,
                itemBuilder: (context, index) {
                  if (index >= posts.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  
                  final post = posts[index];

                  return PostCardModern(
                    post: post,
                    currentUserId: postsState.currentUserId,
                    onLike: () {
                      context.read<PostsBloc>().add(LikePostEvent(post.id));
                    },
                    onDelete: () {
                      context.read<PostsBloc>().add(DeletePostEvent(post.id));
                    },
                    onComment: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CommentsSheet(contentId: post.id),
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
    );
  }
}
