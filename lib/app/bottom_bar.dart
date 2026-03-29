import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:helmove/core/services/callkit_incoming_service.dart';
import 'package:helmove/core/services/permissions_service.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/features/drawer/app_drawer.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_event.dart';
import 'package:helmove/l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(context);
      if (l10n == null) {
        return;
      }
      final permissionsService = sl<PermissionsService>();
      final granted = await permissionsService.requestAllStartupPermissions();

      if (!context.mounted) {
        return;
      }

        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Expanded(
                    child: Text(l10n.communicationPermissionsRequired),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () =>
                        ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: l10n.settings,
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
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    // RESPONSIVE ÖLÇEKLEME: Ekran genişliğine göre 0.85 ile 1.2 arasında bir çarpan üretir.
    // Standart 390px genişliği (iPhone 12/13 vs) baz alınmıştır.
    final double scale = (size.width / 390).clamp(0.85, 1.2);

    // Responsive değişkenler (Sadece scale ile çarpıyoruz)
    final double iconSizeUnselected = 26.0 * scale;
    final double iconSizeSelected = 28.0 * scale;
    final double addIconSize = 48.0 * scale;
    final double fontSize = 11.0 * scale;

    // Barın yüksekliği: Temel 65px + Cihazın alt boşluğu (Home çizgisi)
    final double navBarHeight =
        (65.0 * scale) + (bottomPadding > 0 ? bottomPadding : 15.0);

    // Shell indices: 0(Home), 1(Discover), 2(Map), 3(Communication)
    // UI indices:    0(Home), 1(Discover), 2(AddPost), 3(Map), 4(Communication)
    int currentIndex = navigationShell.currentIndex;
    if (currentIndex >= 2) {
      currentIndex++;
    }

    return Scaffold(
      key: mainScaffoldKey,
      resizeToAvoidBottomInset: false,
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
                fontSize: fontSize, // Responsive font
                fontStyle: FontStyle.normal,
                color: theme.colorScheme.primary,
              );
            }
            return AppTextStyles.medium.copyWith(
              fontSize: fontSize, // Responsive font
              fontStyle: FontStyle.normal,
              color: const Color.fromARGB(255, 128, 117, 104),
            );
          }),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: NavigationBar(
              height: navBarHeight, // Responsive yükseklik
              elevation: 0,
              backgroundColor: theme.colorScheme.surface.withAlpha(180),
              selectedIndex: currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) async {
                if (index == 2) {
                  _showAddOptionsBottomSheet(context);
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
                  final activeSessionId = voiceSessionBloc.state.session?.id;

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
                  label: l10n.home,
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
                  label: l10n.bottomNavDiscover,
                ),
                NavigationDestination(
                  icon: Image.asset(
                    'assets/icons/ic_add2.png',
                    width: addIconSize,
                    height: addIconSize,
                  ),
                  label: l10n.add,
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
                  label: l10n.map,
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
                  label: l10n.bottomNavCommunication,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.shareSheetTitle,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              _buildAddOption(
                context,
                icon: Icons.camera_alt_outlined,
                title: l10n.shareSheetCameraTitle,
                subtitle: l10n.shareSheetCameraSubtitle,
                onTap: () {
                  context.pop();
                  context.push('/add_post');
                },
              ),
              const SizedBox(height: 16),
              _buildAddOption(
                context,
                icon: Icons.photo_library_outlined,
                title: l10n.shareSheetGalleryTitle,
                subtitle: l10n.shareSheetGallerySubtitle,
                onTap: () async {
                  context.pop();
                  final picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null && context.mounted) {
                    context.push('/prepare_media', extra: File(image.path));
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildAddOption(
                context,
                icon: Icons.edit_note_outlined,
                title: l10n.shareSheetJotsTitle,
                subtitle: l10n.shareSheetJotsSubtitle,
                onTap: () {
                  context.pop();
                  context.push('/create_jots');
                },
              ),
              // Bottom safely padding for mobile devices
              SizedBox(height: MediaQuery.viewPaddingOf(context).bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
            color: colorScheme.onSurface.withValues(alpha: 0.03),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
