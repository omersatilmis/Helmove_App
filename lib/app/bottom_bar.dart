import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/core/di/injection_container.dart';
import 'package:moto_comm_app_1/core/services/callkit_incoming_service.dart';
import 'package:moto_comm_app_1/core/services/permissions_service.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/drawer/app_drawer.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_event.dart';

final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

class BottomBarWrapper extends StatelessWidget {
  static bool _communicationPermissionsBootstrapped = false;

  final StatefulNavigationShell navigationShell;

  const BottomBarWrapper({super.key, required this.navigationShell});

  Future<void> _ensureCommunicationPermissions(BuildContext context) async {
    if (_communicationPermissionsBootstrapped) {
      return;
    }
    _communicationPermissionsBootstrapped = true;

    try {
      final permissionsService = sl<PermissionsService>();
      final granted = await permissionsService.requestAllStartupPermissions();

      if (!context.mounted) {
        return;
      }

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tam sesli sohbet deneyimi icin Mikrofon, Bluetooth, Konum ve Arama izinleri gereklidir.',
            ),
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ayarlar',
              textColor: Colors.white,
              onPressed: PermissionsService.openSettings,
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await sl<CallKitIncomingService>().requestPermissions();
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const double iconSizeUnselected = 26.0;
    const double iconSizeSelected = 28.0;

    // Shell indices: 0(Home), 1(Discover), 2(Map), 3(Communication)
    // UI indices:    0(Home), 1(Discover), 2(AddPost), 3(Map), 4(Communication)
    int currentIndex = navigationShell.currentIndex;
    if (currentIndex >= 2) {
      currentIndex++;
    }

    return Scaffold(
      key: mainScaffoldKey,
      extendBody: true,
      drawer: const AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.bold.copyWith(
                fontSize: 11,
                fontStyle: FontStyle.normal,
                color: theme.colorScheme.primary,
              );
            }
            return AppTextStyles.medium.copyWith(
              fontSize: 11,
              fontStyle: FontStyle.normal,
              color: const Color.fromARGB(255, 128, 117, 104),
            );
          }),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: NavigationBar(
              height: 80,
              elevation: 0,
              backgroundColor: theme.colorScheme.surface.withAlpha(180),
              selectedIndex: currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) async {
                if (index == 2) {
                  context.push('/add_post');
                  return;
                }

                if (index == 4 && currentIndex != 4) {
                  await ensureCommunicationRuntimeStarted();
                  if (!context.mounted) {
                    return;
                  }

                  await _ensureCommunicationPermissions(context);
                  if (!context.mounted) {
                    return;
                  }

                  final voiceSessionBloc = BlocProvider.of<VoiceSessionBloc>(
                    context,
                  );
                  final activeSessionId =
                      voiceSessionBloc.state.activeSession?.id ??
                      voiceSessionBloc.state.session?.id;

                  voiceSessionBloc.add(
                    const GetMyVoiceSessionsEvent(immediate: true),
                  );

                  if (activeSessionId != null && activeSessionId > 0) {
                    voiceSessionBloc.add(
                      GetVoiceSessionDetailsEvent(
                        activeSessionId,
                        immediate: true,
                      ),
                    );
                  }
                }

                int shellIndex = index;
                if (index > 2) {
                  shellIndex--;
                }

                navigationShell.goBranch(
                  shellIndex,
                  initialLocation: shellIndex == navigationShell.currentIndex,
                );
              },
              destinations: [
                NavigationDestination(
                  icon: Image.asset(
                    'assets/icons/ic_home1.png',
                    width: iconSizeUnselected,
                    height: iconSizeUnselected,
                  ),
                  selectedIcon: Image.asset(
                    'assets/icons/ic_home2.png',
                    width: iconSizeSelected,
                    height: iconSizeSelected,
                  ),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  icon: Image.asset(
                    'assets/icons/ic_discover1.png',
                    width: iconSizeUnselected,
                    height: iconSizeUnselected,
                  ),
                  selectedIcon: Image.asset(
                    'assets/icons/ic_discover2.png',
                    width: iconSizeSelected,
                    height: iconSizeSelected,
                  ),
                  label: 'Keşfet',
                ),
                NavigationDestination(
                  icon: Image.asset(
                    'assets/icons/ic_add2.png',
                    width: 48,
                    height: 48,
                  ),
                  label: 'Gönderi Ekle',
                ),
                NavigationDestination(
                  icon: Image.asset(
                    'assets/icons/ic_map1.png',
                    width: iconSizeUnselected,
                    height: iconSizeUnselected,
                  ),
                  selectedIcon: Image.asset(
                    'assets/icons/ic_map2.png',
                    width: iconSizeSelected,
                    height: iconSizeSelected,
                  ),
                  label: 'Harita',
                ),
                NavigationDestination(
                  icon: Image.asset(
                    'assets/icons/ic_comm1.png',
                    width: iconSizeUnselected,
                    height: iconSizeUnselected,
                  ),
                  selectedIcon: Image.asset(
                    'assets/icons/ic_comm2.png',
                    width: iconSizeSelected,
                    height: iconSizeSelected,
                  ),
                  label: 'İletişim',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
