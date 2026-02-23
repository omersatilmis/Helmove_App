import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/app/bottom_bar.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/login_page.dart';
import 'package:moto_comm_app_1/features/auth/presentation/pages/register_page.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/communication/presentation/models/invite_args.dart';
import '../../features/communication/presentation/pages/invite_page.dart';
import 'package:moto_comm_app_1/core/widgets/app_bloc_listener.dart'; // Import AppBlocListener
// Removed CallListenerWrapper import

// 🔥 YENİ SAYFALARIN IMPORTLARI
import 'package:moto_comm_app_1/features/homepage/presentation/pages/home_page.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:moto_comm_app_1/features/discover/presentation/pages/discover_page.dart';
import 'package:moto_comm_app_1/features/addpost/presentation/pages/add_post_page.dart';
import 'package:moto_comm_app_1/features/map/presentation/pages/map_page.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/communication_page.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/create_group_ride.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/group_page.dart';
import 'package:moto_comm_app_1/features/communication/presentation/pages/group_settings.dart';
import 'package:moto_comm_app_1/features/media/presentation/pages/prepare_media_page.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_bloc.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/bloc/group_ride_event.dart';

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
import 'package:moto_comm_app_1/core/services/version_service.dart';
import 'package:moto_comm_app_1/core/presentation/pages/force_update_page.dart';

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

    // Unified Redirect Guard (Version Check + Auth)
    redirect: (context, state) async {
      // 1. Force Update Check (Highest Priority)
      final versionService = sl<VersionService>();
      final isUpdateRequired = await versionService.isUpdateRequired();

      final isForceUpdating = state.uri.toString() == '/force-update';

      if (isUpdateRequired && !isForceUpdating) {
        return '/force-update';
      }

      // 2. Auth Logic
      // Kullanıcı giriş yapmış mı?
      bool isLoggedIn = authProvider.isAuthenticated;

      // Eğer senkron kontrolde giriş yoksa, asenkron (local token) kontrol et
      if (!isLoggedIn) {
        isLoggedIn = await authProvider.checkAuthStatus();
      }

      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (!isLoggedIn) {
        if (!isLoggingIn && !isRegistering && !isForceUpdating) {
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
      GoRoute(
        path: '/force-update',
        builder: (context, state) => const ForceUpdatePage(),
      ),

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
          // Provide GLOBAL Blocs here so they persist across tabs
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    sl<GroupRideBloc>()..add(const LoadActiveGroupRidesEvent()),
              ),
              BlocProvider.value(value: sl<VoiceSessionBloc>()),
            ],
            child: AppBlocListener(
              child: BottomBarWrapper(navigationShell: navigationShell),
            ),
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
