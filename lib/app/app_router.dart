import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/app/bottom_bar.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/login_page.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/register_page.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_bloc.dart';
import 'package:moto_comm_app_1/features/content/posts/presentation/bloc/posts_event.dart';

// 🔥 YENİ SAYFALARIN IMPORTLARI
import 'package:moto_comm_app_1/features/homepage/presentation/pages/home_page.dart';
import 'package:moto_comm_app_1/features/discover/presentation/pages/discover_page.dart';
import 'package:moto_comm_app_1/features/addpost/presentation/pages/add_post_page.dart';
import 'package:moto_comm_app_1/features/map/presentation/pages/map_page.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/communication_page.dart';
import 'package:moto_comm_app_1/features/media/presentation/pages/prepare_media_page.dart';

// Drawer Sayfalarının Importları
import 'package:moto_comm_app_1/features/profile/presentation/pages/profile_page.dart';
import 'package:moto_comm_app_1/features/profile/presentation/pages/edit_profile.dart';
import 'package:moto_comm_app_1/features/plan/presentation/pages/plan_page.dart';
import 'package:moto_comm_app_1/features/communities/presentation/pages/communities_page.dart';
import 'package:moto_comm_app_1/features/settings/presentation/pages/settings_page.dart';
import 'package:moto_comm_app_1/features/help/presentation/pages/help_page.dart';
import 'package:moto_comm_app_1/features/settings/presentation/pages/my_garage_page.dart';

// Homepage den girilen sayfaların Importları
import 'package:moto_comm_app_1/features/messages/presentation/pages/messages_page.dart';
import 'package:moto_comm_app_1/features/notification/presentation/pages/notification_page.dart';

// Profile Jots Tabından açılan sayfa
import 'package:moto_comm_app_1/features/content/jots/presentation/pages/create_jot_page.dart';

// Arkadaşlık sayfası
import 'package:moto_comm_app_1/features/friendship/presentation/pages/friends_page.dart';

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

// --- REFACTOR: Router'ı bir fonksiyon haline getirdik ---
// Böylece AuthProvider'ı dinleyip yönlendirme yapabiliriz.

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/homepage',

    // AuthProvider'ı dinle: Oturum durumu değişince yönlendir
    refreshListenable: authProvider,

    redirect: (context, state) async {
      // 1. Kullanıcı giriş yapmış mı?
      // AuthProvider'da isLoggedIn bool olarak tutulmalı veya buradan kontrol edilmeli.
      // En sağlıklısı AuthProvider içinde bir getter veya method olması.
      final isLoggedIn = await authProvider.checkAuthStatus();

      // Sadece kontrol amaçlı (döngüye girmesin diye)
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (!isLoggedIn) {
        // Giriş yapmamışsa ve zaten login/register sayfasında değilse -> Login'e git
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
      } else {
        // Giriş yapmışsa ve login/register sayfasındaysa -> HomePage'e git
        if (isLoggingIn || isRegistering) {
          return '/homepage';
        }
      }

      return null; // Değişiklik yok
    },

    routes: [
      // --- 1. TAM EKRAN SAYFALAR ---
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Drawer içinden gidilen sayfalar
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'];
          return ProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(path: '/plans', builder: (context, state) => const PlanPage()),
      GoRoute(
        path: '/communities',
        builder: (context, state) => const CommunitiesPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/my-garage',
        builder: (context, state) => const MyGaragePage(),
      ),
      GoRoute(path: '/help', builder: (context, state) => const HelpPage()),

      // Homepage topbarından  gidilen sayfalar
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ConversationsPage(),
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

      // Arkadaşlık sayfası
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsPage(),
      ),

      // Top level add post (Fullscreen)
      GoRoute(
        path: '/add_post',
        builder: (context, state) => const AddPostPage(),
      ),

      GoRoute(
        path: '/prepare_media',
        builder: (context, state) {
          final file = state.extra as dynamic;
          return PrepareMediaPage(imageFile: file);
        },
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
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      sl<PostsBloc>()..add(const GetFeedEvent()),
                  child: const HomePageWithDrawer(),
                ),
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
          // Şube 3: Harita (YENİLENDİ)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapPage(),
              ),
            ],
          ),
          // Şube 4: İletişim (YENİLENDİ)
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
}
