import 'package:flutter/material.dart';
import 'package:moto_comm_app_1/app/app_router.dart';
import 'package:moto_comm_app_1/core/theme/app_theme.dart'; // YENİ TEMA DOSYASI

class MotoCommApp extends StatelessWidget {
  const MotoCommApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MotoComm',
      debugShowCheckedModeBanner: false,
      
      routerConfig: router,
      
      // 🔥 YENİ TEMALARI BURAYA BAĞLIYORUZ
      theme: AppTheme.lightTheme, // Varsayılan (Açık)
      darkTheme: AppTheme.darkTheme, // Karanlık Mod
      themeMode: ThemeMode.system, // Telefonun ayarına göre otomatik değişir
    );
  }
}
