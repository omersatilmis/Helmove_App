import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/app/bottom_bar.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/features/auth/presentation/pages/login_page.dart';
import 'package:helmove/features/auth/presentation/pages/register_page.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/communication/presentation/models/invite_args.dart';
import '../../features/communication/presentation/pages/invite_page.dart';
import 'package:helmove/core/widgets/app_bloc_listener.dart';
// Removed CallListenerWrapper import

// 🔥 YENİ SAYFALARIN IMPORTLARI
import 'package:helmove/features/homepage/presentation/pages/home_page.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:helmove/features/discover/presentation/bloc/discover_bloc.dart';
import 'package:helmove/features/discover/presentation/pages/discover_page.dart';
import 'package:helmove/features/discover/presentation/pages/discover_search_page.dart';
import 'package:helmove/features/addpost/presentation/pages/add_post_page.dart';
import 'package:helmove/features/map/presentation/pages/map_page.dart';
import 'package:helmove/features/map/presentation/providers/map_bloc.dart';
import 'package:helmove/features/communication/presentation/pages/communication_page.dart';
import 'package:helmove/features/communication/presentation/pages/create_group_ride.dart';
import 'package:helmove/features/communication/presentation/pages/group_page.dart';
import 'package:helmove/features/communication/presentation/pages/group_settings.dart';
import 'package:helmove/features/media/presentation/pages/prepare_media_page.dart';
import 'package:helmove/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:helmove/features/group_ride/presentation/bloc/group_ride_bloc.dart';

// Drawer Sayfalarının Importları
import 'package:helmove/features/profile/presentation/pages/profile_page.dart';
import 'package:helmove/features/profile/presentation/pages/edit_profile.dart';
import 'package:helmove/features/plan/presentation/pages/plan_page.dart';
import 'package:helmove/features/communities/presentation/pages/communities_page.dart';
import 'package:helmove/features/settings/presentation/pages/settings_page.dart';
import 'package:helmove/features/help/presentation/pages/help_page.dart';
import 'package:helmove/features/settings/presentation/pages/my_garage_page.dart';
import 'package:helmove/features/settings/presentation/pages/support/feedback_page.dart';
import 'package:helmove/features/settings/presentation/pages/support/copyright_page.dart';
import 'package:helmove/features/settings/presentation/pages/support/privacy_policy_page.dart';
import 'package:helmove/features/settings/presentation/pages/support/about_app_page.dart';
import 'package:helmove/features/settings/presentation/pages/blocked_users_page.dart';
import 'package:helmove/features/settings/presentation/pages/security_page.dart';
import 'package:helmove/features/settings/presentation/pages/change_password_page.dart';

// Homepage den girilen sayfaların Importları
import 'package:helmove/features/messages/presentation/pages/messages_page.dart';
import 'package:helmove/features/notification/presentation/pages/notification_page.dart';

// Profile Jots Tabından açılan sayfa
import 'package:helmove/features/content/jots/presentation/pages/create_jot_page.dart';
import 'package:helmove/features/content/jots/presentation/bloc/jots_bloc.dart';
import 'package:helmove/features/content/posts/presentation/pages/user_posts_feed_page.dart';
import 'package:helmove/features/content/posts/presentation/bloc/posts_bloc.dart';

// Arkadaşlık sayfası
import 'package:helmove/features/friendship/presentation/pages/friends_page.dart';

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

final rootNavigatorKey = GlobalKey<NavigatorState>();

// --- REFACTOR: Router'ı bir fonksiyon haline getirdik ---
// Böylece AuthProvider'ı dinleyip yönlendirme yapabiliriz.

GoRouter createRouter(AuthProvider authProvider) {
  int? parseRouteInt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return int.tryParse(raw);
  }

  GroupRideArgs? resolveGroupRideArgs(GoRouterState state) {
    final extraArgs = GroupRideArgs.fromExtra(state.extra);
    if (extraArgs != null) {
      final hasAnyValidId =
          extraArgs.rideId > 0 || ((extraArgs.sessionId ?? 0) > 0);
      if (hasAnyValidId) {
        return extraArgs;
      }
    }

    final rideId =
        parseRouteInt(state.pathParameters['rideId']) ??
        parseRouteInt(state.uri.queryParameters['rideId']);
    final sessionId =
        parseRouteInt(state.pathParameters['sessionId']) ??
        parseRouteInt(state.uri.queryParameters['sessionId']);

    if ((rideId ?? 0) <= 0 && (sessionId ?? 0) <= 0) {
      return null;
    }

    final effectiveRideId = (rideId != null && rideId > 0)
        ? rideId
        : (sessionId ?? 0);
    final nameCandidate = state.uri.queryParameters['groupName']?.trim();

    return GroupRideArgs(
      rideId: effectiveRideId,
      sessionId: sessionId,
      groupName: (nameCandidate == null || nameCandidate.isEmpty)
          ? 'Grup Sürüşü'
          : nameCandidate,
    );
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: authProvider,
    initialLocation: '/homepage',

    // Unified Redirect Guard (Auth)
    redirect: (context, state) async {
      // Auth Logic
      // Kullanıcı giriş yapmış mı?
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
          if (userId == null || userId.isEmpty) {
            return const ProfilePage();
          }
          return ProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: '/profile/:userId/posts',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const Scaffold(body: Center(child: Text('Hata: Veri eksik')));
          
          final initialIndex = extra['initialIndex'] as int;
          final postsBloc = extra['postsBloc'] as PostsBloc;
          
          return UserPostsFeedPage(
            initialIndex: initialIndex,
            postsBloc: postsBloc,
          );
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
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackPage(),
      ),
      GoRoute(
        path: '/copyright',
        builder: (context, state) => const CopyrightPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: '/blocked-users',
        builder: (context, state) => const BlockedUsersPage(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),

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
        builder: (context, state) => BlocProvider(
          create: (context) => sl<JotsBloc>(),
          child: const CreateJotsPage(),
        ),
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
        redirect: (context, state) {
          if (state.extra == null || state.extra is! File) {
            return '/homepage';
          }
          return null;
        },
        builder: (context, state) {
          final file = state.extra as File;
          return PrepareMediaPage(imageFile: file);
        },
      ),

      // --- 2. BOTTOM BARLI SAYFALAR ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Provide GLOBAL Blocs lazily so startup does not instantiate
          // communication stacks before they are actually used.
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => sl<GroupRideBloc>()),
              BlocProvider(create: (context) => sl<VoiceSessionBloc>()),
            ],
            child: BottomBarWrapper(navigationShell: navigationShell),
          );
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
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => BlocProvider(
                      create: (context) => sl<DiscoverBloc>(),
                      child: const DiscoverSearchPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Şube 3: Harita (YENİLENDİ)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => BlocProvider(
                  create: (context) => sl<MapBloc>(),
                  child: const MapPage(),
                ),
              ),
            ],
          ),
          // Şube 4: İletişim (YENİLENDİ)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/communication',
                builder: (context, state) =>
                    const AppBlocListener(child: CommunicationPage()),
                routes: [
                  GoRoute(
                    path: 'create-group-ride',
                    builder: (context, state) => const CreateGroupRide(),
                  ),
                  // GroupPage'i buraya 'child' (alt rota) olarak ekle
                  GoRoute(
                    path: 'group-page', // başında / yok dikkat
                    redirect: (context, state) {
                      final args = resolveGroupRideArgs(state);
                      if (args == null) {
                        return '/communication';
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final args = resolveGroupRideArgs(state)!;
                      return GroupPage(data: args);
                    },
                  ),
                  GoRoute(
                    path: 'group-page/:rideId',
                    redirect: (context, state) {
                      final args = resolveGroupRideArgs(state);
                      if (args == null) {
                        return '/communication';
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final args = resolveGroupRideArgs(state)!;
                      return GroupPage(data: args);
                    },
                  ),
                  GoRoute(
                    path: 'group-page/session/:sessionId',
                    redirect: (context, state) {
                      final args = resolveGroupRideArgs(state);
                      if (args == null) {
                        return '/communication';
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final args = resolveGroupRideArgs(state)!;
                      return GroupPage(data: args);
                    },
                  ),
                  GoRoute(
                    path: 'invite',
                    redirect: (context, state) {
                      final args = InviteArgs.fromExtra(state.extra);
                      if (args == null || !args.isValid) {
                        return '/communication';
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final args = InviteArgs.fromExtra(state.extra)!;
                      return InvitePage(args: args);
                    },
                  ),
                  GoRoute(
                    path: 'group-settings',
                    redirect: (context, state) {
                      final args = GroupRideArgs.fromExtra(state.extra);
                      if (args == null || !args.isValid) {
                        return '/communication';
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final args = GroupRideArgs.fromExtra(state.extra)!;
                      return GroupSettings(data: args);
                    },
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
