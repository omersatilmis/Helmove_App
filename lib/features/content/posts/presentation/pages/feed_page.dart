import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import '../widgets/post_card.dart';
import '../../../../interaction/presentation/widgets/comments_sheet.dart';
import 'package:helmove/core/di/injection_container.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  static const int _feedPageSize = 10;

  final ScrollController _scrollController = ScrollController();
  late final PostsBloc _postsBloc;

  @override
  void initState() {
    super.initState();
    _postsBloc = sl<PostsBloc>();
    _postsBloc.add(const GetFeedEvent(page: 1, limit: _feedPageSize));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final state = _postsBloc.state;
      if (state.status != PostsStatus.loading && state.hasNextPage) {
        _postsBloc.add(
          GetFeedEvent(page: state.page + 1, limit: _feedPageSize),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsBloc, PostsState>(
      bloc: _postsBloc,
      builder: (context, state) {
        if (state.status == PostsStatus.loading && state.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == PostsStatus.failure && state.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ??
                      AppLocalizations.of(context)!.unknownError,
                  style: AppTextStyles.medium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _postsBloc.add(
                      const GetFeedEvent(
                        isRefresh: true,
                        page: 1,
                        limit: _feedPageSize,
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        if (state.posts.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noPostsYet,
              style: AppTextStyles.medium.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _postsBloc.add(
              const GetFeedEvent(
                isRefresh: true,
                page: 1,
                limit: _feedPageSize,
              ),
            );
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.hasReachedMax
                ? state.posts.length
                : state.posts.length + 1,
            itemBuilder: (context, index) {
              if (index >= state.posts.length) {
                return const _BottomLoader();
              }

              final post = state.posts[index];
              final isLast =
                  state.hasReachedMax && index == state.posts.length - 1;

              return Padding(
                padding: isLast
                    ? const EdgeInsets.only(bottom: 80)
                    : EdgeInsets.zero,
                child: PostCardModern(
                  post: post,
                  currentUserId: state.currentUserId,
                  onDelete: () {
                    _postsBloc.add(DeletePostEvent(post.id));
                  },
                  onLike: () {
                    _postsBloc.add(
                      LikePostEvent(post.id, currentIsLiked: post.isLiked),
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
                          _postsBloc.add(
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
                  onSave: () {},
                  onReport: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.reportReceived,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
