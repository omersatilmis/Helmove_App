import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/app/bottom_bar.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/login_page.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/register_page.dart';

// 🔥 YENİ SAYFALARIN IMPORTLARI
import 'package:moto_comm_app_1/features/homepage/presentation/pages/home_page.dart';
import 'package:moto_comm_app_1/features/discover/presentation/pages/discover_page.dart';
import 'package:moto_comm_app_1/features/addpost/presentation/pages/add_post_page.dart';
import 'package:moto_comm_app_1/features/map/presentation/pages/map_page.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/communication_page.dart';

// Drawer Sayfalarının Importları
import 'package:moto_comm_app_1/features/profile/presentation/pages/profile_page.dart';
import 'package:moto_comm_app_1/features/plan/presentation/pages/plan_page.dart';
import 'package:moto_comm_app_1/features/communities/presentation/pages/communities_page.dart';
import 'package:moto_comm_app_1/features/settings/presentation/pages/settings_page.dart';
import 'package:moto_comm_app_1/features/help/presentation/pages/help_page.dart';

// Homepage den girilen sayfaların Importları
import 'package:moto_comm_app_1/features/messages/presentation/pages/messages_page.dart';
import 'package:moto_comm_app_1/features/notification/presentation/pages/notification_page.dart';

// Profile Jots Tabından açılan sayfa
import 'package:moto_comm_app_1/features/profile/presentation/widgets/tabs/jots/create_jots.dart';

// --- Placeholder (Hala yapmadığımız yan sayfalar için kalsın) ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(title)),
  );
}
// -------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/homepage',
  routes: [
    // --- 1. TAM EKRAN SAYFALAR ---
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // Drawer içinden gidilen sayfalar
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/plans', builder: (context, state) => const PlanPage()),
    GoRoute(
      path: '/communities',
      builder: (context, state) => const CommunitiesPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(path: '/help', builder: (context, state) => const HelpPage()),

    // Homepage topbarından  gidilen sayfalar
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    // Profile Jots Tabından açılan sayfa
    GoRoute(
      path: '/create_jots',
      builder: (context, state) => const CreateJotsPage(),
    ),

    // --- 2. BOTTOM BARLI SAYFALAR ---
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BottomBarWrapper(navigationShell: navigationShell);
      },
      branches: [
        // Şube 1: Ana Sayfa
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/homepage',
              builder: (context, state) => const HomePageWithDrawer(),
            ),
          ],
        ),
        // Şube 2: Keşfet (YENİLENDİ)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/discover',
              builder: (context, state) => const DiscoverPage(),
            ),
          ],
        ),
        // Şube 3: Paylaş (YENİLENDİ)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/add_post',
              builder: (context, state) => const AddPostPage(),
            ),
          ],
        ),
        // Şube 4: Harita (YENİLENDİ)
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/map', builder: (context, state) => const MapPage()),
          ],
        ),
        // Şube 5: İletişim (YENİLENDİ)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/communication',
              builder: (context, state) => const CommunicationPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
