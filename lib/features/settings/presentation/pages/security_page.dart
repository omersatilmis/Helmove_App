import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/l10n/app_localizations.dart';
import '../widgets/structure/settings_tile.dart';
import '../widgets/structure/settings_section_header.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings_security), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SettingsSectionHeader(title: l10n.accountSecurity),
            SettingsTile(
              icon: Icons.password_rounded,
              title: l10n.changePassword,
              subtitle: l10n.changePasswordSubtitle,
              onTap: () {
                context.push('/change-password');
              },
            ),

            /*           
            SettingsTile(
              icon: Icons.security_rounded,
              title: "İki Faktörlü Doğrulama",
              subtitle: "Hesabını daha güvenli hale getir",
              trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              onTap: () {
                // Placeholder
              },
            ),

            const SizedBox(height: 16),
            const SettingsSectionHeader(title: "Giriş Hareketleri"),
            SettingsTile(
              icon: Icons.devices_rounded,
              title: "Aktif Oturumlar",
              subtitle: "Hangi cihazlardan giriş yapıldığını gör",
              onTap: () {
                // TODO: Active sessions page
              },
            ),

            const SizedBox(height: 16),
            const SettingsSectionHeader(title: "Gelişmiş"),
            SettingsTile(
              icon: Icons.delete_forever_rounded,
              title: "Hesabı Sil",
              isDestructive: true,
              subtitle: "Hesabını kalıcı olarak sil",
              onTap: () {
                _showDeleteAccountDialog(context);
              },
            ),
            */
          ],
        ),
      ),
    );
  }

  /*
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text('Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete account logic
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }*/
}
