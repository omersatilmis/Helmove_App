import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helmove/core/config/app_feature_flags.dart';
import 'package:helmove/features/settings/domain/entities/privacy_settings_entity.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_event.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/helper_widgets.dart'; 
import 'package:helmove/l10n/app_localizations.dart';

class PrivacySection extends StatefulWidget {
  const PrivacySection({super.key});

  @override
  State<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<PrivacySection> {
  // State Değişkenleri
  String _ghostMode = ""; // Initialized in didChangeDependencies
  String _messagePrivacy = "";
  String _tagPrivacy = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    if (_ghostMode.isEmpty) _ghostMode = l10n.onlyFriends;
    if (_messagePrivacy.isEmpty) _messagePrivacy = l10n.everyone;
    if (_tagPrivacy.isEmpty) _tagPrivacy = l10n.followers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.privacyLocation),

        // 👻 HAYALET MOD (GHOST MODE)
        // Konum gizliliği en kritik ayar olduğu için en üste koyduk.
        if (AppFeatureFlags.showGhostMode)
          SettingsSelectionTile(
            icon: Icons.visibility_off_outlined, // Gizlilik ikonu
            title: l10n.ghostMode,
            currentValue: _ghostMode,
            options: [
              l10n.everyone,
              l10n.onlyFriends,
              l10n.privateNobody,
            ],
            onSelect: (val) {
              setState(() => _ghostMode = val);

              // Backend Mapping (Örnek)
              int locationPrivacyValue = 1; // Sadece Arkadaşlar (Varsayılan)
              if (val == l10n.everyone) locationPrivacyValue = 0;
              if (val == l10n.privateNobody) locationPrivacyValue = 2;

              context.read<SettingsBloc>().add(
                UpdatePrivacyEvent(
                  PrivacySettingsEntity(
                    locationPrivacy: locationPrivacyValue,
                    ghostMode: val == l10n.privateNobody,
                  ),
                ),
              );
            },
          ),

        // 💬 MESAJ İSTEKLERİ
        if (AppFeatureFlags.showMessageRequests)
          SettingsSelectionTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.messageRequests,
            currentValue: _messagePrivacy,
            options: [l10n.everyone, l10n.onlyFollowed],
            onSelect: (val) {
              setState(() => _messagePrivacy = val);
              context.read<SettingsBloc>().add(
                const UpdatePrivacyEvent(
                  PrivacySettingsEntity(
                    // showProfileToOthers örneği olarak kullanabiliriz
                  ),
                ),
              );
            },
          ),

        // 🏷️ ETİKETLEME (MENTIONS)
        if (AppFeatureFlags.showTaggingling)
          SettingsSelectionTile(
            icon: Icons.alternate_email_rounded, // @ işareti ikonu
            title: l10n.tagging,
            currentValue: _tagPrivacy,
            options: [l10n.everyone, l10n.followers, l10n.nobody],
            onSelect: (val) => setState(() => _tagPrivacy = val),
          ),

        // 🚫 ENGELLENEN HESAPLAR
        // Bu bir seçim değil, bir liste sayfasına gidiş olduğu için standart SettingsTile kullandık.
        SettingsTile(
          icon: Icons.block_flipped,
          title: l10n.blockedAccounts,
          onTap: () {
            context.push('/blocked-users');
          },
        ),
      ],
    );
  }
}
