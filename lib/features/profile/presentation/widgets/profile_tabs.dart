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
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
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

class ProfileTabViews extends StatelessWidget {
  const ProfileTabViews({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      //physics: NeverScrollableScrollPhysics(), // Sadece tablara tıklayınca geçiş yapsın.
      children: [
        ProfileAboutTab(), // Info (Hakkında)
        ProfileJotsTab(), // Jots (Yazılar)
        ProfilePostsTab(), // Posts (Grid)
        ProfileReelsTab(), // Reels (Video)
        ProfileTaggedTab(), // Tagged (Şimdilik Post ile aynı)
      ],
    );
  }
}
