import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:helmove/core/utils/app_logger.dart';

class AddContentBottomSheet {
  static void show(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final rootContext = context;
    final router = GoRouter.of(context);
    if (l10n == null) return;

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
                            router.push('/add_post');
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
                            await _pickFromGalleryAndOpenPrepareMedia(
                              rootContext,
                              router,
                            );
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
                            router.push('/create_jots');
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

  static Widget _buildAddOption(
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
                  borderRadius: BorderRadius.circular(
                    (16.0 * scale).clamp(10.0, 20.0),
                  ),
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

  static Future<void> _pickFromGalleryAndOpenPrepareMedia(
    BuildContext context,
    GoRouter router,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    try {
      // Bottom sheet kapanış animasyonunun tamamlanmasını bekle.
      await Future<void>.delayed(const Duration(milliseconds: 120));

      // Android: READ_MEDIA_IMAGES (API 33+) or READ_EXTERNAL_STORAGE (older).
      // iOS: Permission.photos. image_picker handles its own prompts internally
      // but an explicit check catches denied states before we even open the picker.
      if (Platform.isAndroid) {
        var status = await Permission.photos.request();
        if (!status.isGranted) {
          // On Android < 13 Permission.photos maps to READ_MEDIA_IMAGES which
          // doesn't exist, so the OS returns denied — fall back to storage.
          status = await Permission.storage.request();
        }
        if (!status.isGranted) {
          AppLogger.warning('Gallery permission denied: $status');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.image_upload_error)),
            );
          }
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited) {
          AppLogger.warning('iOS photos permission denied: $status');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.image_upload_error)),
            );
          }
          return;
        }
      }

      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2048,
      );

      if (image == null) {
        return;
      }

      AppLogger.info('Gallery picked: path=${image.path} name=${image.name}');

      final file = await _resolvePickedImageFile(image);
      if (file == null) {
        AppLogger.warning('_resolvePickedImageFile returned null for path=${image.path}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.image_upload_error)),
          );
        }
        return;
      }

      AppLogger.info('Resolved gallery image: ${file.path} (${await file.length()} bytes)');
      if (!context.mounted) return;
      await router.push('/prepare_media', extra: file);
    } catch (e, st) {
      AppLogger.error('Gallery pick failed', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.image_upload_error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  static Future<File?> _resolvePickedImageFile(XFile image) async {
    final ext = _safeExtension(image.name.isNotEmpty ? image.name : image.path);

    // Primary: saveTo — handles content:// URIs correctly on all Android versions.
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/picked_${DateTime.now().millisecondsSinceEpoch}$ext');
      await image.saveTo(tempFile.path);
      final length = await tempFile.exists() ? await tempFile.length() : 0;
      if (length > 0) return tempFile;
      AppLogger.warning('saveTo produced 0-byte file for ${image.path}');
    } catch (e) {
      AppLogger.warning('saveTo failed for ${image.path}: $e');
    }

    // Fallback: readAsBytes — works with content:// URIs and cloud photos.
    try {
      final bytes = await image.readAsBytes();
      if (bytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/picked_${DateTime.now().millisecondsSinceEpoch}$ext');
        await tempFile.writeAsBytes(bytes, flush: true);
        if (await tempFile.length() > 0) return tempFile;
      }
      AppLogger.warning('readAsBytes returned empty for ${image.path}');
    } catch (e) {
      AppLogger.warning('readAsBytes failed for ${image.path}: $e');
    }

    // Last resort: direct file path (works only when image_picker gave a real path).
    try {
      final direct = File(image.path);
      if (await direct.exists() && await direct.length() > 0) return direct;
    } catch (e) {
      AppLogger.warning('Direct File access failed for ${image.path}: $e');
    }

    return null;
  }

  static String _safeExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot > -1 && dot < path.length - 1) {
      final ext = path.substring(dot);
      if (ext.length <= 6) return ext;
    }
    return '.jpg';
  }
}
