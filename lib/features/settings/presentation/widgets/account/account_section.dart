import 'package:flutter/material.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/l10n/app_localizations.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.account),

        SettingsTile(
          icon: Icons.person_outline_rounded,
          title: l10n.editProfile,
          subtitle: l10n.nameSurnamePhoto,
          onTap: () {
            context.push('/edit-profile');
          },
        ),

        // 🔥 Sürücülere Özel: Garajım
        SettingsTile(
          icon: Icons.two_wheeler_rounded, // Motor ikonu
          title: l10n.myGarage,
          subtitle: l10n.addManageBikes,
          onTap: () {
            context.push('/my-garage');
          },
        ),

        SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: l10n.security,
          onTap: () {
            context.push('/security');
          },
        ),
      ],
    );
  }
}
