import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_application_1/features/drawer/app_drawer.dart'; 
import 'package:flutter_application_1/core/theme/text_styles.dart';

final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();

class BottomBarWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomBarWrapper({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.colorScheme.surface;

    // 🔥 MERKEZİ KONTROL: Boyutları buradan ayarlıyoruz
    const double iconSizeUnselected = 26.0; // Seçili olmayan boyutu
    const double iconSizeSelected = 28.0;   // Seçili olan boyutu

    return Scaffold(
      key: mainScaffoldKey,
      drawer: const AppDrawer(),
      body: navigationShell,

      // 🎨 BOTTOM BAR TASARIMI
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // 1. Arkadaki sabit ışığı kapatır (Zaten vardı)
          indicatorColor: Colors.transparent, 
          
          // 🔥 2. YENİ EKLENDİ: Tıklayınca çıkan dalgalanma (ripple) efektini kapatır
          overlayColor: WidgetStateProperty.all(Colors.transparent),

          // 🔥 YAZI STİLLERİ
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.bold.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic, 
                color: theme.colorScheme.primary,
              );
            }
            return AppTextStyles.medium.copyWith(
              fontSize: 11,
              fontStyle: FontStyle.normal,
              color: const Color.fromARGB(255, 128, 117, 104),
            );
          }),
        ),
        child: NavigationBar(
          height: 80, 
          elevation: 2,
          shadowColor: const Color.fromARGB(255, 80, 56, 12),
          backgroundColor: backgroundColor,
          
          selectedIndex: navigationShell.currentIndex,
          
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          
          // 🔥 BOYUTLAR DEĞİŞKENLERDEN GELİYOR
          destinations: [
            
            // 1. ANA SAYFA
            NavigationDestination(
              icon: Image.asset(
                'assets/icons/ic_home1.png',
                width: iconSizeUnselected, 
                height: iconSizeUnselected,
              ),
              selectedIcon: Image.asset(
                'assets/icons/ic_home2.png',
                width: iconSizeSelected, 
                height: iconSizeSelected,
              ),
              label: 'Ana Sayfa',
            ),

            // 2. KEŞFET
            NavigationDestination(
              icon: Image.asset(
                'assets/icons/ic_discover1.png',
                width: iconSizeUnselected, 
                height: iconSizeUnselected,
              ),
              selectedIcon: Image.asset(
                'assets/icons/ic_discover2.png',
                width: iconSizeSelected, 
                height: iconSizeSelected,
              ),
              label: 'Keşfet',
            ),

            // 3. PAYLAŞ (ORTA BUTON)
            NavigationDestination(
              icon: Image.asset(
                'assets/icons/ic_add2.png', 
                width: 48, 
                height: 48,
              ),
              label: 'Gönderi Ekle',
            ),

            // 4. HARİTA
            NavigationDestination(
              icon: Image.asset(
                'assets/icons/ic_map1.png',
                width: iconSizeUnselected, 
                height: iconSizeUnselected,
              ),
              selectedIcon: Image.asset(
                'assets/icons/ic_map2.png',
                width: iconSizeSelected, 
                height: iconSizeSelected,
              ),
              label: 'Harita',
            ),

            // 5. İLETİŞİM
            NavigationDestination(
              icon: Image.asset(
                'assets/icons/ic_comm1.png',
                width: iconSizeUnselected, 
                height: iconSizeUnselected,
              ),
              selectedIcon: Image.asset(
                'assets/icons/ic_comm2.png',
                width: iconSizeSelected, 
                height: iconSizeSelected,
              ),
              label: 'İletişim',
            ),
          ],
        ),
      ),
    );
  }
}