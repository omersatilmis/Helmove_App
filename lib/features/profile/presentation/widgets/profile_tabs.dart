import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';

import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/profile_about_tab.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/profile_posts_tab.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/profile_jots_tab.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/profile_reels_tab.dart';
import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/profile_tagged_tab.dart';

class ProfileTabBarSliver extends StatelessWidget {
  const ProfileTabBarSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileTabBarDelegate(),
    );
  }
}

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: TabBar(
        // 🔥 1. DEĞİŞİKLİK: Scroll'u kapattık. Artık hepsi ekrana eşit yayılacak.
        isScrollable: false,

        // 🔥 2. DEĞİŞİKLİK: TabAlignment sadece scrollable iken çalışır, siliyoruz.
        // tabAlignment: TabAlignment.center,

        // 🔥 3. DEĞİŞİKLİK: 5 tane tab olduğu için yan boşlukları sıfırlıyoruz ki sığsınlar.
        labelPadding: EdgeInsets.symmetric(horizontal: 0),

        labelColor: AppColors.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha:0.6),
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        // İndikatör tabın tamamını kaplasın (label değil, tab genişliği kadar)
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,

        labelStyle: AppTextStyles.medium.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 12, // Sığması için fontu 1 tık küçülttüm (13 -> 12)
        ),
        unselectedLabelStyle: AppTextStyles.regular.copyWith(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),

        tabs: const [
          // Icon ve Text alt alta (Column gibi) durursa daha az yer kaplar ama
          // TabBar default olarak yan yana veya duruma göre ayarlar.
          // Sığma sorunu olursa sadece Icon kullanmayı düşünebilirsin.
          Tab(text: "About", icon: Icon(Icons.info_outline_rounded)),
          Tab(text: "Jots", icon: Icon(Icons.edit_note_rounded)),
          Tab(text: "Posts", icon: Icon(Icons.grid_view_rounded)),
          Tab(text: "Reels", icon: Icon(Icons.video_collection_outlined)),
          Tab(text: "Tagged", icon: Icon(Icons.assignment_ind_outlined)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

class ProfileTabViews extends StatefulWidget {
  const ProfileTabViews({super.key});

  @override
  State<ProfileTabViews> createState() => _ProfileTabViewsState();
}

class _ProfileTabViewsState extends State<ProfileTabViews> {
  // Instagram Mantığı: Başlangıçta sadece ilk tab (About) yüklü.
  final List<bool> _loadedTabs = [true, false, false, false, false];
  late TabController _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // DefaultTabController'dan controller'ı alıyoruz
    _tabController = DefaultTabController.of(context);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_loadedTabs[_tabController.index]) {
      setState(() {
        _loadedTabs[_tabController.index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        const ProfileAboutTab(),
        _loadedTabs[1] ? const ProfileJotsTab() : const SizedBox.shrink(),
        _loadedTabs[2] ? const ProfilePostsTab() : const SizedBox.shrink(),
        _loadedTabs[3] ? const ProfileReelsTab() : const SizedBox.shrink(),
        _loadedTabs[4] ? const ProfileTaggedTab() : const SizedBox.shrink(),
      ],
    );
  }
}
