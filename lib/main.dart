import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:moto_comm_app_1/core/di/injection_container.dart' as di;
import 'package:moto_comm_app_1/core/di/injection_container.dart';

import 'package:moto_comm_app_1/app/app_router.dart';
import 'package:moto_comm_app_1/core/theme/app_theme.dart';
import 'package:moto_comm_app_1/core/theme/theme_provider.dart';

import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/auth/domain/repositories/auth_repository.dart';
import 'package:moto_comm_app_1/core/services/notification_service.dart';
import 'package:moto_comm_app_1/core/services/call_listener_service.dart';
import 'package:moto_comm_app_1/core/services/app_session.dart';
import 'package:moto_comm_app_1/core/services/real_time_service.dart';
import 'package:moto_comm_app_1/features/intercom/domain/intercom_engine.dart';
import 'package:moto_comm_app_1/features/intercom/domain/intercom_models.dart';
import 'package:moto_comm_app_1/features/intercom/presentation/widgets/intercom_debug_overlay.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Dependency Injection Kurulumu
  await di.init();

  // 1.1 AppSession hydrate (local storage'dan tek sefer)
  final persistedUser = await sl<AuthRepository>().getPersistedUser();
  if (persistedUser != null) {
    sl<AppSession>().updateSession(
      currentUserId: persistedUser.id,
      currentUser: persistedUser,
      token: persistedUser.token,
    );
  } else {
    sl<AppSession>().clearSession();
  }

  // 1.5 Notification Check
  await sl<NotificationService>().initialize();

  // 1.6 Real-time orchestration (AppSession token stream -> SignalR lifecycle)
  sl<RealTimeService>().start();

  // 1.7 Intercom engine bootstrap
  await sl<IntercomEngine>().start();

  // 2. Date Formatting Başlatma (Türkçe için)
  await initializeDateFormatting('tr_TR', null);

  // 3. Call Listener Service — widget tree dışında
  sl<CallListenerService>().start();

  // 4. Root widget — MultiProvider YOK.
  //    Providers artık MaterialApp.router(builder:) içinde
  //    enjekte ediliyor → root mount derinliği ~42 frame azaldı.
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final AuthProvider _authProvider;
  late final ThemeProvider _themeProvider;
  late final IntercomEngine _intercomEngine;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // GetIt'ten alıyoruz — artık Provider tree'den değil.
    _authProvider = sl<AuthProvider>();
    _themeProvider = sl<ThemeProvider>();
    _intercomEngine = sl<IntercomEngine>();
    _router = createRouter(_authProvider);
    // Tema değiştiğinde MaterialApp'ı yeniden çizdir
    _themeProvider.addListener(_onThemeChanged);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);
      _intercomEngine.onConnectivityChanged(online: online);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final mapped = _mapLifecycleState(state);
    _intercomEngine.onLifecycleChanged(mapped);
  }

  IntercomLifecycleState _mapLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        return IntercomLifecycleState.resumed;
      case AppLifecycleState.inactive:
        return IntercomLifecycleState.inactive;
      case AppLifecycleState.paused:
        return IntercomLifecycleState.paused;
      case AppLifecycleState.detached:
        return IntercomLifecycleState.detached;
      case AppLifecycleState.hidden:
        return IntercomLifecycleState.hidden;
    }
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ları tamamen kaldırdık - GetIt'ten erişilecek veya
    // sayfa seviyesinde wrap edilecek. MaterialApp.router(builder:)
    // bile mount derinliği artırıyor.
    return MaterialApp.router(
      title: 'Rider App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeProvider.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (!kDebugMode) return child;
        return Stack(
          children: [
            child,
            const IntercomDebugOverlay(),
          ],
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
