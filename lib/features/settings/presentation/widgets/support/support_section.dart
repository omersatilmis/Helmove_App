import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';

class SupportSection extends StatefulWidget {
  const SupportSection({super.key});

  @override
  State<SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends State<SupportSection> {
  String _version = "";
  final String _appReleaseStage = "Beta"; // Geliştirme aşaması

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Destek"),

        SettingsTile(
          icon: Icons.help_outline_rounded,
          title: "Yardım Merkezi",
          onTap: () => context.push('/help-center'),
        ),
        SettingsTile(
          icon: Icons.feedback_outlined,
          title: "Geri Bildirim Gönder",
          onTap: () => context.push('/feedback'),
        ),
        SettingsTile(
          icon: Icons.copyright_rounded,
          title: "Telif Hakkı",
          onTap: () => context.push('/copyright'),
        ),
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: "Gizlilik Politikası",
          onTap: () => context.push('/privacy-policy'),
        ),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: "Hakkında",
          subtitle: _version.isNotEmpty
              ? "v$_version ($_appReleaseStage)"
              : "Yükleniyor...",
          onTap: () => context.push('/about'),
        ),

        // Çıkış Butonu
        SettingsTile(
          icon: Icons.logout_rounded,
          title: "Çıkış Yap",
          isDestructive: true,
          trailing: const SizedBox(),
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Uygulamadan çıkış yapmak istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text(
              "Çıkış Yap",
              style: TextStyle(
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
