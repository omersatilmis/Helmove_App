import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import '../widgets/post_card.dart';
import '../../../../interaction/presentation/widgets/comments_sheet.dart';

class UserPostsFeedPage extends StatefulWidget {
  final int initialIndex;
  final PostsBloc postsBloc;

  const UserPostsFeedPage({
    super.key,
    required this.initialIndex,
    required this.postsBloc,
  });

  @override
  State<UserPostsFeedPage> createState() => _UserPostsFeedPageState();
}

class _UserPostsFeedPageState extends State<UserPostsFeedPage> {
  late final ScrollController _scrollController;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Attempt to scroll to the initial post after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialPost();
    });
  }

  void _scrollToInitialPost() {
    if (widget.initialIndex <= 0) return;
    
    // We try to estimate the offset because lazy ListView hasn't built distant items.
    // A post card typically has a media area (childAspectRatio 1.0 or similar) 
    // and some text/actions. Average height is around 400-600.
    const double estimatedHeight = 500.0; 
    final offset = widget.initialIndex * estimatedHeight;
    
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(offset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.postsBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.posts),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).pop(),
          ),
        ),
        body: BlocBuilder<PostsBloc, PostsState>(
          builder: (context, state) {
            return ListView.builder(
              controller: _scrollController,
              itemCount: state.posts.length,
              cacheExtent: 1000, // Build more items to help with scrolling
              itemBuilder: (context, index) {
                final post = state.posts[index];
                return PostCardModern(
                  key: _itemKeys.putIfAbsent(index, () => GlobalKey()),
                  post: post,
                  currentUserId: state.currentUserId,
                  onDelete: () {
                    context.read<PostsBloc>().add(DeletePostEvent(post.id));
                  },
                  onLike: () {
                    context.read<PostsBloc>().add(LikePostEvent(post.id));
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
                  onSave: () {},
                  onReport: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.reportReceived)),
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
