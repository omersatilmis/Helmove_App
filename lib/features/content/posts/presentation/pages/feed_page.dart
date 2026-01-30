import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/text_styles.dart';
import '../../../../../core/widgets/app_button_frosted.dart';
import '../bloc/posts_bloc.dart';
import '../bloc/posts_event.dart';
import '../bloc/posts_state.dart';
import '../widgets/post_card.dart';
import 'create_post_page.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PostsBloc>()..add(const GetFeedEvent()),
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          title: Text('Akış', style: AppTextStyles.h3),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AppFrostedButton(
                icon: Icons.add,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostPage(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      // Refresh feed if post created
                      context.read<PostsBloc>().add(
                        const GetFeedEvent(isRefresh: true),
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
        body: BlocBuilder<PostsBloc, PostsState>(
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
                padding: const EdgeInsets.only(
                  top: 16,
                ), // Sadece üstten boşluk, yanlar post_card içinde
                itemCount: state.hasReachedMax
                    ? state.posts.length
                    : state.posts.length + 1,
                itemBuilder: (context, index) {
                  if (index >= state.posts.length) {
                    // Bottom Loader
                    context.read<PostsBloc>().add(
                      GetFeedEvent(page: state.page + 1),
                    );
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final post = state.posts[index];
                  // TODO: Get current user ID roughly for simplicity or pass it
                  // For now assuming we can't delete unless we know ID match
                  return PostCardModern(
                    post: post,
                    isCurrentUser:
                        false, // Update logic when we have User ID access easily
                    onDelete: () {
                      context.read<PostsBloc>().add(DeletePostEvent(post.id));
                    },
                    onLike: () {
                      // TODO: Implement like logic
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
      ),
    );
  }
}
