import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart' as di;
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/discover_event.dart';
import '../bloc/discover_state.dart';
import '../widgets/discover_content_grid.dart';
import '../widgets/discover_shimmer.dart';
import '../../../content/posts/presentation/bloc/posts_bloc.dart';
import 'discovery_feed_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late final TextEditingController _searchController;
  final Future<void> _initFuture = di.initDeferredFeatures();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(BuildContext? blocContext) {
    if (blocContext == null) return;
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      blocContext.read<DiscoverBloc>().add(SearchUsersEvent(query: query));
    } else {
      blocContext.read<DiscoverBloc>().add(const LoadDiscoveryContent(isRefresh: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ARAMA ÇUBUĞU - Her zaman görünür
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AppInputField(
                controller: _searchController,
                type: AppInputType.discover,
                hint: "Kullanıcı ara...",
                leadingIcon: Icons.search,
                suffixWidget: FutureBuilder(
                  future: _initFuture,
                  builder: (context, snapshot) {
                    final ready = snapshot.connectionState == ConnectionState.done;
                    return TextButton(
                      onPressed: ready ? () => _performSearch(context) : null,
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      child: const Text("Ara"),
                    );
                  },
                ),
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _performSearch(context),
              ),
            ),

            // İÇERİK ALANI - Altyapıyı ve Veriyi Bekleyen Kısım
            Expanded(
              child: FutureBuilder(
                future: _initFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const DiscoverShimmer();
                  }

                  // Altyapı (GetIt) hazır, BLoC'u kur
                  return BlocProvider(
                    create: (context) => sl<DiscoverBloc>()..add(const LoadDiscoveryContent()),
                    child: Builder(
                      builder: (blocContext) {
                        return BlocBuilder<DiscoverBloc, DiscoverState>(
                          builder: (context, state) {
                            if (state is DiscoverLoading) {
                              return const DiscoverShimmer();
                            } else if (state is DiscoverFailure) {
                              return Center(child: Text(state.message));
                            } else if (state is DiscoverLoaded) {
                              return _buildSearchResults(state, theme);
                            } else if (state is DiscoverDiscoveryLoaded) {
                              return _buildDiscoveryGrid(state, theme, blocContext);
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(DiscoverLoaded state, ThemeData theme) {
    final results = state.results;
    if (results.isEmpty) {
      return const Center(child: Text("Sonuç bulunamadı."));
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePictureUrl != null
                  ? CachedNetworkImageProvider(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text("${user.firstName ?? ''} ${user.lastName ?? ''}"),
            subtitle: Text("@${user.username}"),
            onTap: () {
              context.push('/profile/${user.id}');
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscoveryGrid(
    DiscoverDiscoveryLoaded state,
    ThemeData theme,
    BuildContext blocContext,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        final bloc = blocContext.read<DiscoverBloc>();
        bloc.add(const LoadDiscoveryContent(isRefresh: true));
        await bloc.stream.firstWhere(
          (s) => s is DiscoverDiscoveryLoaded || s is DiscoverFailure,
        );
      },
      child: DiscoverContentGrid(
        content: state.content,
        hasReachedMax: state.hasReachedMax,
        onLoadMore: () {
          blocContext.read<DiscoverBloc>().add(const LoadDiscoveryContent());
        },
        onTap: (content, index) {
          final postsBloc = sl<PostsBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: blocContext.read<DiscoverBloc>()),
                  BlocProvider.value(value: postsBloc),
                ],
                child: DiscoveryFeedPage(
                  initialPosts: content,
                  initialIndex: index,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
