import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helmove/core/config/app_feature_flags.dart';
import 'package:helmove/features/settings/domain/entities/privacy_settings_entity.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:helmove/features/settings/presentation/bloc/settings_event.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:helmove/features/settings/presentation/widgets/structure/helper_widgets.dart'; // 🔥 Helper'ı dahil ettik

class PrivacySection extends StatefulWidget {
  const PrivacySection({super.key});

  @override
  State<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<PrivacySection> {
  // State Değişkenleri
  String _ghostMode = "Sadece Arkadaşlar"; // Hayalet Mod varsayılanı
  String _messagePrivacy = "Herkes";
  String _tagPrivacy = "Takipçiler";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Gizlilik ve Konum"),

        // 👻 HAYALET MOD (GHOST MODE)
        // Konum gizliliği en kritik ayar olduğu için en üste koyduk.
        if (AppFeatureFlags.showGhostMode)
          SettingsSelectionTile(
            icon: Icons.visibility_off_outlined, // Gizlilik ikonu
            title: "Hayalet Mod",
            currentValue: _ghostMode,
            options: const [
              "Herkes",
              "Sadece Arkadaşlar",
              "Gizli (Kimse Göremez)",
            ],
            onSelect: (val) {
              setState(() => _ghostMode = val);

              // Backend Mapping (Örnek)
              int locationPrivacyValue = 1; // Sadece Arkadaşlar (Varsayılan)
              if (val == "Herkes") locationPrivacyValue = 0;
              if (val == "Gizli (Kimse Göremez)") locationPrivacyValue = 2;

              context.read<SettingsBloc>().add(
                UpdatePrivacyEvent(
                  PrivacySettingsEntity(
                    locationPrivacy: locationPrivacyValue,
                    ghostMode: val == "Gizli (Kimse Göremez)",
                  ),
                ),
              );
            },
          ),

        // 💬 MESAJ İSTEKLERİ
        if (AppFeatureFlags.showMessageRequests)
          SettingsSelectionTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: "Mesaj İstekleri",
            currentValue: _messagePrivacy,
            options: const ["Herkes", "Sadece Takip Ettiklerim"],
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
            title: "Etiketleme",
            currentValue: _tagPrivacy,
            options: const ["Herkes", "Takipçiler", "Hiç Kimse"],
            onSelect: (val) => setState(() => _tagPrivacy = val),
          ),

        // 🚫 ENGELLENEN HESAPLAR
        // Bu bir seçim değil, bir liste sayfasına gidiş olduğu için standart SettingsTile kullandık.
        SettingsTile(
          icon: Icons.block_flipped,
          title: "Engellenen Hesaplar",
          onTap: () {
            // context.push('/blocked-users');
          },
        ),
      ],
    );
  }
}
