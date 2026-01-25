import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:moto_comm_app_1/core/theme/app_colors.dart';

class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Destek"),

        SettingsTile(
          icon: Icons.help_outline_rounded,
          title: "Yardım Merkezi",
          onTap: () {},
        ),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: "Hakkında",
          subtitle: "v1.0.0 (Beta)",
          onTap: () {},
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
