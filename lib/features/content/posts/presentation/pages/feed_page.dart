import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import '../widgets/post_card.dart';
import 'package:provider/provider.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../core/di/injection_container.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<PostsBloc>().add(const GetFeedEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    // Use ProfileProvider to get the current user's ID (more reliable on app startup)
    final profileProvider = context.watch<ProfileProvider>();
    final currentUserIdInt = profileProvider.profile?.id;

    return BlocProvider(
      create: (context) => sl<PostsBloc>()..add(const GetFeedEvent()),
      child: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
          // Need to set up listeners for refresh here if we want to support result from CreatePostPage
          // But for now let's focus on the crash/loop.

          if (state.status == PostsStatus.loading && state.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PostsStatus.failure && state.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Bir hata oluştu',
                    style: AppTextStyles.medium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PostsBloc>().add(
                        const GetFeedEvent(isRefresh: true),
                      );
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (state.posts.isEmpty) {
            return Center(
              child: Text(
                'Henüz gönderi yok.',
                style: AppTextStyles.medium.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<PostsBloc>().add(
                const GetFeedEvent(isRefresh: true),
              );
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 16),
              itemCount: state.hasReachedMax
                  ? state.posts.length
                  : state.posts.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.posts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final post = state.posts[index];
                final isOwner =
                    currentUserIdInt != null && post.userId == currentUserIdInt;

                return PostCardModern(
                  post: post,
                  isCurrentUser: isOwner,
                  onDelete: () {
                    context.read<PostsBloc>().add(DeletePostEvent(post.id));
                  },
                  onLike: () {
                    context.read<PostsBloc>().add(LikePostEvent(post.id));
                  },
                  onComment: () {
                    // TODO: Implement comment logic
                  },
                  onShare: () {
                    // TODO: Implement share logic
                  },
                  onSave: () {
                    // TODO: Implement save logic
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
