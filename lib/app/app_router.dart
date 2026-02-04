import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/app/bottom_bar.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/login_page.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/register_page.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/invite_page.dart';
// 🔥 YENİ SAYFALARIN IMPORTLARI
import 'package:moto_comm_app_1/features/homepage/presentation/pages/home_page.dart';
import 'package:moto_comm_app_1/features/discover/presentation/pages/discover_page.dart';
import 'package:moto_comm_app_1/features/addpost/presentation/pages/add_post_page.dart';
import 'package:moto_comm_app_1/features/map/presentation/pages/map_page.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/communication_page.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/create_group_ride.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/group_page.dart';
import 'package:moto_comm_app_1/features/communication/domain/entities/group_ride_data.dart';
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
      // Senkron kontrol (UI için hızlı)
      bool isLoggedIn = authProvider.isAuthenticated;

      // Eğer senkron kontrolde giriş yoksa, asenkron (local token) kontrol et
      if (!isLoggedIn) {
        isLoggedIn = await authProvider.checkAuthStatus();
      }

      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (!isLoggedIn) {
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
      } else {
        if (isLoggingIn || isRegistering) {
          return '/homepage';
        }
      }

      return null;
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
                routes: [
                  GoRoute(
                    path: 'create-group-ride',
                    builder: (context, state) => const CreateGroupRide(),
                  ),
                  // GroupPage'i buraya 'child' (alt rota) olarak ekle
                  GoRoute(
                    path: 'group-page', // başında / yok dikkat
                    builder: (context, state) {
                      final data =
                          state.extra as GroupRideData? ??
                          GroupRideData(
                            groupName: "Weekend Riders",
                            maxParticipants: 8,
                            currentParticipants: 4,
                            sessionDuration: "01:19",
                            privacy: "Public",
                            destination: "Abant Gölü",
                            ridingStyle: "Sakin Sürüş",
                          );
                      return GroupPage(data: data);
                    },
                  ),
                  GoRoute(
                    path: 'invite',
                    builder: (context, state) => const InvitePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
