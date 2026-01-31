import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import '../widgets/post_card.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../interaction/presentation/widgets/comments_sheet.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final ScrollController _scrollController = ScrollController();
  late final PostsBloc _postsBloc;

  @override
  void initState() {
    super.initState();
    _postsBloc = sl<PostsBloc>()..add(const GetFeedEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _postsBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _postsBloc.add(GetFeedEvent(page: _postsBloc.state.page + 1));
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
    // Use ProfileProvider to get the current user's ID
    final profileProvider = context.watch<ProfileProvider>();
    final currentUserIdInt = profileProvider.profile?.id;

    return BlocProvider.value(
      value: _postsBloc,
      child: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, state) {
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
                      _postsBloc.add(const GetFeedEvent(isRefresh: true));
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
              _postsBloc.add(const GetFeedEvent(isRefresh: true));
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
                    _postsBloc.add(DeletePostEvent(post.id));
                  },
                  onLike: () {
                    _postsBloc.add(LikePostEvent(post.id));
                  },
                  onComment: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsSheet(contentId: post.id),
                    );
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
