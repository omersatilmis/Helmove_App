import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_bloc.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_event.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_state.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';

class ProfilePostsTab extends StatefulWidget {
  const ProfilePostsTab({super.key});

  @override
  State<ProfilePostsTab> createState() => _ProfilePostsTabState();
}

class _ProfilePostsTabState extends State<ProfilePostsTab> {
  late PostsBloc _postsBloc;

  @override
  void initState() {
    super.initState();
    _postsBloc = sl<PostsBloc>();
    _loadPosts();
  }

  void _loadPosts() {
    final profileProvider = context.read<ProfileProvider>();
    final user = profileProvider.visitedProfile ?? profileProvider.profile;
    if (user != null) {
      _postsBloc.add(GetUserPostsEvent(userId: user.id));
    }
  }

  @override
  void dispose() {
    _postsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.visitedProfile ?? profileProvider.profile;

    final authProvider = context.watch<AuthProvider>();
    final currentUserIdStr = authProvider.currentUser?.id;
    final currentUserId = currentUserIdStr != null
        ? int.tryParse(currentUserIdStr)
        : null;

    final bool isMe = user?.id == currentUserId;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final Color placeholderColor =
        Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1C1C1E)
        : const Color.fromARGB(255, 166, 166, 175);

    return BlocProvider.value(
      value: _postsBloc,
      child: CustomScrollView(
        key: const PageStorageKey('posts_tab'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              if (state.status == PostsStatus.loading) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (state.posts.isEmpty && state.status != PostsStatus.failure) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text(
                        "Henüz gönderi yok.",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 2),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 1.5,
                    crossAxisSpacing: 1.5,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = state.posts[index];
                    final hasMedia =
                        post.mediaUrl != null && post.mediaUrl!.isNotEmpty;

                    return InkWell(
                      onTap: () {
                        // TODO: Detay sayfasına git
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: placeholderColor,
                            child: hasMedia
                                ? CachedNetworkImage(
                                    imageUrl: post.mediaUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Container(color: placeholderColor),
                                    errorWidget: (context, url, error) =>
                                        const Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                        ),
                                  )
                                : Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      post.text,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                          ),
                          if (isMe)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: AppColors.darkSurface,
                                      builder: (context) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                              ),
                                              title: const Text(
                                                'Sil',
                                                style: TextStyle(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.pop(context);
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor:
                                                        AppColors.darkSurface,
                                                    title: const Text(
                                                      'Postu Sil',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    content: const Text(
                                                      'Bu gönderiyi silmek istediğine emin misin?',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          'İptal',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          context
                                                              .read<PostsBloc>()
                                                              .add(
                                                                DeletePostEvent(
                                                                  post.id,
                                                                ),
                                                              );
                                                        },
                                                        child: const Text(
                                                          'Sil',
                                                          style: TextStyle(
                                                            color:
                                                                AppColors.error,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.more_horiz,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }, childCount: state.posts.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
