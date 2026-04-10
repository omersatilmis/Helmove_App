import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/di/injection_container.dart' as di;
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/utils/friendship_error_mapper.dart';
import 'package:helmove/l10n/app_localizations.dart';
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
  DiscoverBloc? _discoverBloc;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  void _ensureDiscoverRuntime() {
    if (_discoverBloc != null) return;

    _discoverBloc = sl<DiscoverBloc>()..add(const LoadDiscoveryContent());
  }

  @override
  void dispose() {
    _discoverBloc?.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const DiscoverShimmer();
            }

            _ensureDiscoverRuntime();
            final discoverBloc = _discoverBloc!;

            return BlocProvider.value(
              value: discoverBloc,
              child: Builder(
                builder: (blocContext) {
                  return Column(
                    children: [
                      // ARAMA ÇUBUĞU - Tıklandığında Arama Sayfasına Gider
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            context.push('/discover/search');
                          },
                          child: AbsorbPointer(
                            child: AppInputField(
                              controller: _searchController,
                              type: AppInputType.discover,
                              hint: AppLocalizations.of(context)!.searchUserHint,
                              leadingIcon: Icons.search,
                            ),
                          ),
                        ),
                      ),

                      // İÇERİK ALANI - Sadece Keşfet Izgarası
                      Expanded(
                        child: BlocBuilder<DiscoverBloc, DiscoverState>(
                          builder: (context, state) {
                            if (state is DiscoverLoading) {
                              return const DiscoverShimmer();
                            } else if (state is DiscoverFailure) {
                              final l10n = AppLocalizations.of(context)!;
                              final mappedMessage = FriendshipErrorMapper.mapForUi(
                                rawMessage: state.message,
                                l10n: l10n,
                                fallback: l10n.errorOccurred,
                              );
                              return Center(child: Text(mappedMessage));
                            } else if (state is DiscoverDiscoveryLoaded) {
                              return _buildDiscoveryGrid(state, theme, context);
                            }
                            // Eğer başka bir state (örn. DiscoverLoaded) gelirse
                            // tekrar grid yüklemesini tetikle (fallback)
                            if (state is DiscoverLoaded ||
                                state is DiscoverInitial) {
                              context.read<DiscoverBloc>().add(
                                const LoadDiscoveryContent(),
                              );
                              return const DiscoverShimmer();
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
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
