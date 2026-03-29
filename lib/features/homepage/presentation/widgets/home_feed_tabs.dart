import 'package:flutter/material.dart';
import 'package:helmove/features/content/jots/presentation/pages/jot_feed_view.dart';
import 'package:helmove/features/content/posts/presentation/pages/feed_page.dart';
import 'package:helmove/l10n/app_localizations.dart';

class HomeFeedTabs extends StatefulWidget {
  const HomeFeedTabs({super.key});

  @override
  State<HomeFeedTabs> createState() => _HomeFeedTabsState();
}

class _HomeFeedTabsState extends State<HomeFeedTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _hasOpenedJots = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_hasOpenedJots || _tabController.index != 1) {
      return;
    }
    setState(() {
      _hasOpenedJots = true;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          height:
              40, // Boyutu biraz küçülterek yazıları yukarı taşıyoruz (Varsayılan 46)
          child: TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(
              vertical: 0,
            ), // Dikey padding'i sıfırladık
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            indicatorColor: colorScheme.primary,
            indicatorWeight: 2, // Çizgiyi de biraz incelttik
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.postsTab),
              Tab(text: AppLocalizations.of(context)!.jotsTab),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const _PostsFeedTab(),
              _hasOpenedJots ? const _JotsFeedTab() : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostsFeedTab extends StatefulWidget {
  const _PostsFeedTab();

  @override
  State<_PostsFeedTab> createState() => _PostsFeedTabState();
}

class _PostsFeedTabState extends State<_PostsFeedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const FeedView();
  }

  @override
  bool get wantKeepAlive => true;
}

class _JotsFeedTab extends StatefulWidget {
  const _JotsFeedTab();

  @override
  State<_JotsFeedTab> createState() => _JotsFeedTabState();
}

class _JotsFeedTabState extends State<_JotsFeedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const JotFeedView();
  }

  @override
  bool get wantKeepAlive => true;
}
