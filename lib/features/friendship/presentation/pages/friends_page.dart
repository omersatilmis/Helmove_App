import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/widgets/app_frosted_button.dart';
import 'package:helmove/core/widgets/glass_input_field.dart';
import 'package:helmove/features/friendship/presentation/bloc/list/friendship_list_bloc.dart';
import 'package:helmove/features/friendship/presentation/bloc/list/friendship_list_event.dart';
import 'package:helmove/features/friendship/presentation/bloc/list/friendship_list_state.dart';
import 'package:helmove/features/friendship/presentation/bloc/action/friendship_action_bloc.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'widgets/friends_list.dart';
import 'widgets/pending_requests.dart';
import 'widgets/sent_requests.dart';
import 'widgets/search_results_list.dart';

class FriendsPage extends StatefulWidget {
  final int? targetUserId;

  const FriendsPage({super.key, this.targetUserId});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late FriendshipListBloc _searchBloc;
  late FriendshipActionBloc _actionBloc;
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchBloc = sl<FriendshipListBloc>();
    _actionBloc = sl<FriendshipActionBloc>();
    _searchController.addListener(_onSearchChanged);
    
    // Profile stats are only needed in own-friends mode.
    if (widget.targetUserId == null) {
      _searchBloc.add(const LoadFriendshipStatsEvent());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _searchBloc.close();
    _actionBloc.close();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      setState(() {
        _isSearching = query.isNotEmpty;
      });
      if (query.isNotEmpty) {
        _searchBloc.add(SearchFriendsEvent(query: query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwnFriendsPage = widget.targetUserId == null;

    if (!isOwnFriendsPage) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _actionBloc),
          BlocProvider(create: (_) => sl<FriendshipListBloc>()),
        ],
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AppFrostedButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              AppLocalizations.of(context)!.friends,
              style: AppTextStyles.h3,
            ),
            centerTitle: true,
          ),
          body: FriendsList(
            targetUserId: widget.targetUserId,
            showActions: false,
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _actionBloc),
        BlocProvider.value(value: _searchBloc),
      ],
      child: BlocListener<FriendshipListBloc, FriendshipListState>(
        listener: (context, state) {
          if (state is FriendshipStatsLoaded) {
            // 🔥 Hafızaya (cache) kaydet
            context.read<ProfileProvider>().updateFriendsCount(state.stats.totalFriends);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: AppFrostedButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            title: Text(AppLocalizations.of(context)!.friendship, style: AppTextStyles.h3),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Arama Alanı
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassInputField(
                  controller: _searchController,
                  hintText: AppLocalizations.of(context)!.searchFriends,
                  prefixIcon: Icons.search,
                ),
              ),

              if (!_isSearching) ...[
                // 🔥 TAB BAR (Sadece arama yokken göster)
                TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTextStyles.bold.copyWith(fontSize: 14),
                  unselectedLabelStyle: AppTextStyles.medium.copyWith(
                    fontSize: 14,
                  ),
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.myFriends),
                    Tab(text: AppLocalizations.of(context)!.pendingRequests),
                    Tab(text: AppLocalizations.of(context)!.sentRequests),
                  ],
                ),
                // TAB İÇERİKLERİ
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      BlocProvider(
                        create: (_) => sl<FriendshipListBloc>(),
                        child: const FriendsList(),
                      ),
                      BlocProvider(
                        create: (_) => sl<FriendshipListBloc>(),
                        child: const PendingRequests(),
                      ),
                      BlocProvider(
                        create: (_) => sl<FriendshipListBloc>(),
                        child: const SentRequests(),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // 🔍 ARAMA SONUÇLARI
                Expanded(
                  child: BlocProvider.value(
                    value: _searchBloc,
                    child: const SearchResultsList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
