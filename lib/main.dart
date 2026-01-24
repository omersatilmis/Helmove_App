import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🔥 BU EKSİKTİ (Provider paketi)

// 🔥 BU IMPORTLAR EKSİKTİ (Kendi dosyaların)
import 'package:moto_comm_app_1/app/app_router.dart';
import 'package:moto_comm_app_1/core/theme/app_theme.dart';
import 'package:moto_comm_app_1/core/theme/theme_provider.dart';

void main() {
  runApp(
    // Uygulamanın en tepesini Provider ile sarmalıyoruz ki
    // her yerden temaya erişebilelim.
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider'ı dinliyoruz. notifyListeners() tetiklenince burası yeniden çizilir.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Rider App',

      // Temaları tanımlıyoruz
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // 🔥 Büyü burada: Provider'dan gelen moda göre tema değişiyor (System/Light/Dark)
      themeMode: themeProvider.themeMode,

      routerConfig: router, // app_router.dart içindeki router
      debugShowCheckedModeBanner: false,
    );
  }
}
