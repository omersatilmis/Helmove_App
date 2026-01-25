import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:moto_comm_app_1/features/drawer/drawer_item.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Profil bilgilerini dinle
    final profileProvider = context.watch<ProfileProvider>();
    final firstName = profileProvider.firstName;
    final lastName = profileProvider.lastName;
    final email = profileProvider.email;
    final profileImage =
        profileProvider.profileImageUrl ?? 'https://i.pravatar.cc/150?img=11';

    final theme = Theme.of(context);
    // Güvenli alan (Çentik) kontrolü
    final padding = MediaQuery.of(context).padding;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0, // Gölgeyi kaldırdık, daha flat tasarım
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30), // Daha yumuşak kavis
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // -----------------------------------------------------------
          // 🎨 CUSTOM HEADER (GRADYANLI & MODERN)
          // -----------------------------------------------------------
          Container(
            padding: EdgeInsets.only(
              top: padding.top + 20,
              bottom: 30,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(
                    alpha: 0.8,
                  ), // Hafif ton farkı
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                // Profil Resmi (Gölge efektli)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(profileImage),
                    // Resim yüklenmezse diye arka plan
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),

                // İsim ve Mail Bilgisi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$firstName $lastName",
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------
          // 📋 MENÜ LİSTESİ
          // -----------------------------------------------------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              children: [
                //Profilim Alanı
                DrawerItem(
                  iconPath:
                      'assets/icons/ic_profile.png', // 👈 Dosya ismini kendine göre düzelt
                  title: "Profilim",
                  onTap: () {
                    context.pop();
                    context.push('/profile');
                  },
                ),

                // Premium Alanı
                DrawerItem(
                  iconPath:
                      'assets/icons/ic_premium.png', // 👈 Premium ikonu (Yoksa ic_star.png falan koy)
                  title: "Premium Planlar",
                  iconColor: const Color(0xFF9C27B0),
                  textColor: const Color(0xFF9C27B0),
                  backgroundColor: const Color(
                    0xFF9C27B0,
                  ).withValues(alpha: 0.1),
                  onTap: () {
                    context.pop();
                    context.push('/plans');
                  },
                ),

                // Topluluklar Alanı
                DrawerItem(
                  iconPath:
                      'assets/icons/ic_community.png', // 👈 Senin istediğin topluluk ikonu
                  title: "Topluluklar",
                  onTap: () {
                    context.pop();
                    context.push('/communities');
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Divider(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),

                // Ayarlar Alanı
                DrawerItem(
                  iconPath: 'assets/icons/ic_settings.png', // 👈 Ayarlar ikonu
                  title: "Ayarlar",
                  onTap: () {
                    context.pop();
                    context.push('/settings');
                  },
                ),

                // Yardım Alanı
                DrawerItem(
                  iconPath: 'assets/icons/ic_help.png', // 👈 Yardım ikonu
                  title: "Yardım & Destek",
                  onTap: () {
                    context.pop();
                    context.push('/help');
                  },
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------
          // 🚪 ÇIKIŞ YAP
          // -----------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: DrawerItem(
              iconPath: 'assets/icons/ic_logout.png', // 👈 Çıkış ikonu
              title: "Çıkış Yap",
              isDestructive: true,
              onTap: () {
                context.read<AuthProvider>().logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}
