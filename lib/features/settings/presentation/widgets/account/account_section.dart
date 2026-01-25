import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/settings_tile.dart';
import 'package:moto_comm_app_1/features/settings/presentation/widgets/structure/settings_section_header.dart';
import 'package:go_router/go_router.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: "Hesap"),

        SettingsTile(
          icon: Icons.person_outline_rounded,
          title: "Profili Düzenle",
          subtitle: "Ad, Soyad, Fotoğraf",
          onTap: () {
            context.push('/edit-profile');
          },
        ),

        // 🔥 Sürücülere Özel: Garajım
        SettingsTile(
          icon: Icons.two_wheeler_rounded, // Motor ikonu
          title: "Garajım",
          subtitle: "Motorlarını ekle ve yönet",
          onTap: () {
            context.push('/my-garage');
          },
        ),

        SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: "Güvenlik",
          onTap: () {},
        ),
      ],
    );
  }
}
