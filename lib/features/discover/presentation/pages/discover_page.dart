import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../bloc/discover_bloc.dart';
import '../bloc/discover_event.dart';
import '../bloc/discover_state.dart';
import '../widgets/discover_content_grid.dart';
import '../widgets/discover_shimmer.dart';
import 'discovery_feed_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DiscoverBloc>(),
      child: const _DiscoverView(),
    );
  }
}

class _DiscoverView extends StatefulWidget {
  const _DiscoverView();

  @override
  State<_DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<_DiscoverView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Sayfa açıldığında keşfet içeriğini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoverBloc>().add(const LoadDiscoveryContent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    debugPrint('🔍 [DiscoverPage] _performSearch called with query: "$query"');
    if (query.isNotEmpty) {
      context.read<DiscoverBloc>().add(SearchUsersEvent(query: query));
    } else {
      // Boş arama yapıldığında keşfet içeriğine geri dön
      context.read<DiscoverBloc>().add(const LoadDiscoveryContent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keşfet")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppInputField(
              controller: _searchController,
              type: AppInputType.discover,
              hint: "Kullanıcı ara...",
              // Sol tarafa büyüteç ikonu (Hint tarzı)
              leadingIcon: Icons.search,
              // Sağ tarafa "Ara" butonu
              suffixWidget: TextButton(
                onPressed: _performSearch,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha:0.5),
                ),
                child: const Text("Ara"),
              ),
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _performSearch(),
              // prefixWidget kaldırıldı çünkü artık leadingIcon kullanıyoruz
            ),
          ),

          // Controller listener'ı burada attach etmek yerine, AppInputField stateful olduğu için
          // ve build içinde controller veriyoruz. En temizi controller.addListener initState'de.
          // Aşağıda düzeltiyorum.
          Expanded(
            child: BlocBuilder<DiscoverBloc, DiscoverState>(
              builder: (context, state) {
                if (state is DiscoverLoading) {
                  return const DiscoverShimmer();
                } else if (state is DiscoverFailure) {
                  return Center(child: Text(state.message));
                } else if (state is DiscoverLoaded) {
                  final results = state.results;
                  if (results.isEmpty) {
                    return const Center(child: Text("Sonuç bulunamadı."));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final user = results[index];
                      final theme = Theme.of(context);
                      final fullName =
                          "${user.firstName ?? ''} ${user.lastName ?? ''}"
                              .trim();

                      return ListTile(
                        onTap: () {
                          // Profil sayfasına yönlendir
                          context.push('/profile/${user.userId}');
                        },
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          backgroundImage:
                              (user.profilePictureUrl != null &&
                                  user.profilePictureUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(user.profilePictureUrl!)
                              : null,
                          child:
                              (user.profilePictureUrl == null ||
                                  user.profilePictureUrl!.isEmpty)
                              ? Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          fullName.isNotEmpty ? fullName : user.username,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '@${user.username}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  );
                } else if (state is DiscoverDiscoveryLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<DiscoverBloc>().add(
                        const LoadDiscoveryContent(isRefresh: true),
                      );
                    },
                    child: DiscoverContentGrid(
                      content: state.content,
                      hasReachedMax: state.hasReachedMax,
                      onLoadMore: () {
                        context.read<DiscoverBloc>().add(
                          const LoadDiscoveryContent(),
                        );
                      },
                      onTap: (content, index) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiscoveryFeedPage(
                              initialPosts: content,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                // Initial State
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
