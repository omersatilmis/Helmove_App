import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/injection_container.dart' as di; // DI dosyamızı import ettik
import 'core/di/injection_container.dart'; // sl'e erişim için

import 'package:moto_comm_app_1/app/app_router.dart';
import 'package:moto_comm_app_1/core/theme/app_theme.dart';
import 'package:moto_comm_app_1/core/theme/theme_provider.dart';

import 'package:dio/dio.dart';
import 'package:moto_comm_app_1/features/auth/domain/repositories/auth_repository.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/profile/domain/repositories/profile_repository.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Dependency Injection Kurulumu
  await di.init();

  runApp(
    MultiProvider(
      providers: [
        // --- Core ---
        // Dio'yu GetIt'ten alıp Provider olarak sunuyoruz (Opsiyonel: Eğer UI içinde context.read<Dio>() deniyorsa)
        Provider<Dio>(create: (_) => sl<Dio>()),
        // Provider<SharedPreferences>(create: (_) => sl<SharedPreferences>()),

        // --- Repositories ---
        // AuthRepository interface'i üzerinden implementation'ı sunuyoruz
        Provider<AuthRepository>(create: (_) => sl<AuthRepository>()),

        // --- ViewModels / Providers ---
        ChangeNotifierProvider(
          create: (_) => AuthProvider(sl<AuthRepository>()),
        ),

        // --- Profile Provider ---
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(sl<ProfileRepository>()),
        ),

        // --- Theme ---
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Data Sources ve API'yi Provider'a koymaya genellikle gerek kalmaz çünkü
        // Repository pattern sayesinde UI sadece Repository'i (veya UseCase'i) bilir.
        // Ancak yine de eski kodların bozulmaması için AuthRepository yeterli olacaktır.
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Provider'ı dinliyoruz
    final themeProvider = Provider.of<ThemeProvider>(context);
    // AuthProvider'ı dinlemiyoruz (listen: false), sadece router oluşturmak için alıyoruz.
    // Router zaten refreshListenable ile dinliyor.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Her build'de router'ı yeniden oluşturmak yerine, authProvider değişmediği sürece
    // aynı instance'ı kullanmak isteyebiliriz ama GoRouter config'i basit bir obje.
    // En temizi:
    final router = createRouter(authProvider);

    return MaterialApp.router(
      title: 'Rider App',

      // Temaları tanımlıyoruz
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // 🔥 Büyü burada: Provider'dan gelen moda göre tema değişiyor
      themeMode: themeProvider.themeMode,

      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
