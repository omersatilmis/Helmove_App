import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_bloc.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_event.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_state.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

class ProfilePostsTab extends StatefulWidget {
  const ProfilePostsTab({super.key});

  @override
  State<ProfilePostsTab> createState() => _ProfilePostsTabState();
}

class _ProfilePostsTabState extends State<ProfilePostsTab>
    with AutomaticKeepAliveClientMixin {
  // 🔥 MIXIN EKLENDİ
  late PostsBloc _postsBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _postsBloc = sl<PostsBloc>();
    _scrollController.addListener(_onScroll);
    _loadPosts(page: 1);
  }

  void _onScroll() {
    if (_isBottom) {
      final state = _postsBloc.state;
      if (state.hasNextPage && state.status != PostsStatus.loading) {
        _loadPosts(page: state.page + 1);
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadPosts({int page = 1}) {
    final profileProvider = context.read<ProfileProvider>();
    final user = profileProvider.visitedProfile ?? profileProvider.profile;
    if (user != null) {
      _postsBloc.add(GetUserPostsEvent(userId: user.id, page: page, limit: 12));
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _postsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🔥 ŞART!
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.visitedProfile ?? profileProvider.profile;

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
        controller: _scrollController,
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              if (state.status == PostsStatus.loading && state.posts.isEmpty) {
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
                          ).colorScheme.onSurface.withValues(alpha:0.6),
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
                        ],
                      ),
                    );
                  }, childCount: state.posts.length),
                ),
              );
            },
          ),
          BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              if (state.status == PostsStatus.loading &&
                  state.posts.isNotEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
