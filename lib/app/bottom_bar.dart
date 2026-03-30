import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;

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
    final rootContext = context;
    if (l10n == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final media = MediaQuery.of(context);
            final maxSheetWidth = math.min(constraints.maxWidth - 16, 560.0);
            final scale = (maxSheetWidth / 390).clamp(0.85, 1.2);
            final horizontalPadding = (24.0 * scale).clamp(16.0, 32.0);
            final verticalPadding = (26.0 * scale).clamp(18.0, 36.0);
            final optionGap = (16.0 * scale).clamp(10.0, 20.0);
            final sectionGap = (24.0 * scale).clamp(16.0, 30.0);
            final titleBottomGap = (30.0 * scale).clamp(18.0, 36.0);
            final handleWidth = (40.0 * scale).clamp(30.0, 48.0);
            final handleHeight = (4.0 * scale).clamp(3.0, 5.0);
            final maxHeight = media.size.height * 0.9;

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxSheetWidth,
                  maxHeight: maxHeight,
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    media.viewPadding.bottom + (16 * scale),
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular((32.0 * scale).clamp(24.0, 40.0)),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: handleWidth,
                          height: handleHeight,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        Text(
                          l10n.shareSheetTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h3.copyWith(
                            fontSize: (20.0 * scale).clamp(16.0, 24.0),
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: titleBottomGap),
                        _buildAddOption(
                          context,
                          icon: Icons.camera_alt_outlined,
                          title: l10n.shareSheetCameraTitle,
                          subtitle: l10n.shareSheetCameraSubtitle,
                          scale: scale,
                          onTap: () {
                            Navigator.of(context).pop();
                            if (rootContext.mounted) {
                              rootContext.push('/add_post');
                            }
                          },
                        ),
                        SizedBox(height: optionGap),
                        _buildAddOption(
                          context,
                          icon: Icons.photo_library_outlined,
                          title: l10n.shareSheetGalleryTitle,
                          subtitle: l10n.shareSheetGallerySubtitle,
                          scale: scale,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _pickFromGalleryAndOpenPrepareMedia(rootContext);
                          },
                        ),
                        SizedBox(height: optionGap),
                        _buildAddOption(
                          context,
                          icon: Icons.edit_note_outlined,
                          title: l10n.shareSheetJotsTitle,
                          subtitle: l10n.shareSheetJotsSubtitle,
                          scale: scale,
                          onTap: () {
                            Navigator.of(context).pop();
                            if (rootContext.mounted) {
                              rootContext.push('/create_jots');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    double scale = 1.0,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final optionRadius = (20.0 * scale).clamp(14.0, 24.0);
    final optionPadding = (16.0 * scale).clamp(12.0, 20.0);
    final iconPadding = (12.0 * scale).clamp(8.0, 14.0);
    final iconSize = (28.0 * scale).clamp(20.0, 32.0);
    final spacing = (16.0 * scale).clamp(10.0, 18.0);
    final titleSize = (16.0 * scale).clamp(13.0, 18.0);
    final subtitleSize = (13.0 * scale).clamp(11.0, 15.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(optionRadius),
        child: Container(
          padding: EdgeInsets.all(optionPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(optionRadius),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
            color: colorScheme.onSurface.withValues(alpha: 0.03),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular((16.0 * scale).clamp(10.0, 20.0)),
                ),
                child: Icon(icon, color: colorScheme.primary, size: iconSize),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: (2.0 * scale).clamp(1.0, 4.0)),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: subtitleSize,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: (24.0 * scale).clamp(18.0, 28.0),
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGalleryAndOpenPrepareMedia(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );

      if (image == null) {
        return;
      }

      final file = File(image.path);
      if (!file.existsSync()) {
        if (context.mounted && l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.image_upload_error)),
          );
        }
        return;
      }

      if (context.mounted) {
        context.push('/prepare_media', extra: file);
      }
    } catch (_) {
      if (context.mounted && l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.image_upload_error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
