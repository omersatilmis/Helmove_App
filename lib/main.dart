import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_comm_app_1/core/di/injection_container.dart' as di;
import 'package:moto_comm_app_1/core/di/injection_container.dart';

import 'package:moto_comm_app_1/app/app_router.dart';
import 'package:moto_comm_app_1/core/theme/app_theme.dart';
import 'package:moto_comm_app_1/core/theme/theme_provider.dart';

import 'package:dio/dio.dart';
import 'package:moto_comm_app_1/features/auth/domain/repositories/auth_repository.dart';
import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/profile/domain/repositories/profile_repository.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';
import 'package:moto_comm_app_1/core/services/notification_service.dart'; // Import added
import 'package:moto_comm_app_1/features/call/presentation/widgets/call_listener_wrapper.dart'; // Import added
import 'package:intl/date_symbol_data_local.dart'; // LocaleDataException için gerekli

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Dependency Injection Kurulumu
  await di.init();

  // 1.5 Notification Check
  await sl<NotificationService>().initialize(); // Init OneSignal + CallKit

  // 2. Date Formatting Başlatma (Türkçe için)
  await initializeDateFormatting('tr_TR', null);

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
          create: (_) => AuthProvider(
            sl<AuthRepository>(),
            sl<ProfileRepository>(),
            sl<NotificationService>(), // Injected
          ),
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
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router'ı bir kez oluşturuyoruz. authProvider refreshListenable olduğu için
    // yönlendirme kararları içerde otomatik yönetilecek.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _router = createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ı dinliyoruz
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Rider App',

      // Temaları tanımlıyoruz
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // 🔥 Büyü burada: Provider'dan gelen moda göre tema değişiyor
      themeMode: themeProvider.themeMode,

      routerConfig: _router,
      builder: (context, child) {
        return CallListenerWrapper(child: child!);
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
