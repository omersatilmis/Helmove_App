import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:helmove/core/theme/app_colors.dart';
import 'package:helmove/l10n/app_localizations.dart';

class SupportSection extends StatefulWidget {
  const SupportSection({super.key});

  @override
  State<SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends State<SupportSection> {
  String _version = '';
  final String _appReleaseStage = 'Public Beta';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: AppLocalizations.of(context)!.support),

        SettingsTile(
          icon: Icons.feedback_outlined,
          title: AppLocalizations.of(context)!.sendFeedback,
          onTap: () => context.push('/feedback'),
        ),
        SettingsTile(
          icon: Icons.copyright_rounded,
          title: AppLocalizations.of(context)!.copyright,
          onTap: () => context.push('/copyright'),
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: AppLocalizations.of(context)!.privacyPolicy,
          onTap: () => context.push('/privacy-policy'),
        ),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: AppLocalizations.of(context)!.about,
          subtitle: _version.isNotEmpty
              ? AppLocalizations.of(context)!.version(_version, _appReleaseStage)
              : AppLocalizations.of(context)!.loading,
          onTap: () => context.push('/about'),
        ),

        // Çıkış Butonu
        SettingsTile(
          icon: Icons.logout_rounded,
          title: AppLocalizations.of(context)!.logout,
          isDestructive: true,
          trailing: const SizedBox(),
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: Text(
              l10n.logout,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
