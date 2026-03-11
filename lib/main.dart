import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:moto_comm_app_1/core/di/injection_container.dart' as di;
import 'package:moto_comm_app_1/core/di/injection_container.dart';

import 'package:moto_comm_app_1/app/app_router.dart';
import 'package:moto_comm_app_1/core/theme/app_theme.dart';
import 'package:moto_comm_app_1/core/theme/theme_provider.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';

import 'package:moto_comm_app_1/features/auth/presentation/providers/auth_provider.dart';
import 'package:moto_comm_app_1/features/auth/domain/repositories/auth_repository.dart';
import 'package:moto_comm_app_1/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:moto_comm_app_1/core/services/app_session.dart';
import 'package:moto_comm_app_1/core/network/auth_bootstrap_gate.dart';
import 'package:moto_comm_app_1/core/presentation/widgets/connection_status_overlay.dart';
import 'package:moto_comm_app_1/core/utils/app_bloc_observer.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moto_comm_app_1/features/call/presentation/bloc/call_bloc.dart';
import 'package:moto_comm_app_1/features/call/presentation/bloc/call_event.dart';

void main() async {
  // ── runZonedGuarded: Catches ALL unhandled async errors globally ──
  // This is the SAFETY NET that prevents invisible crashes from
  // bloc.dart:231 rethrow escaping to the microtask loop.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Register global BlocObserver so ALL bloc errors are logged
      Bloc.observer = AppBlocObserver();

      // 1. Dependency Injection Kurulumu
      await di.initCore();

      // 1.1 Auth bootstrap: runApp oncesi token'i storage'dan yukle
      final authBootstrapGate = sl<AuthBootstrapGate>();
      String? bootstrappedToken;
      try {
        bootstrappedToken = await sl<AuthLocalDataSource>().getToken();
        if (bootstrappedToken != null && bootstrappedToken.isNotEmpty) {
          final persistedUser = await sl<AuthRepository>().getPersistedUser();
          if (persistedUser != null) {
            sl<AppSession>().updateSession(
              currentUserId: persistedUser.id,
              currentUser: persistedUser,
              token: persistedUser.token,
            );
          } else {
            sl<AppSession>().updateToken(bootstrappedToken);
          }
        } else {
          sl<AppSession>().clearSession();
        }
      } catch (_) {
        sl<AppSession>().clearSession();
      } finally {
        authBootstrapGate.complete();
      }

      // 2. Date Formatting Başlatma (Türkçe için)
      await initializeDateFormatting('tr_TR', null);

      // 3. Root widget
      runApp(const MyApp());
    },
    (error, stackTrace) {
      // ── GLOBAL SAFETY NET ──
      // This catches anything that escapes ALL try-catch blocks.
      // Without this, the app crashes silently.
      debugPrint(
        '🔴🔴🔴 [GLOBAL ERROR CATCHER] Unhandled async error:\n'
        '   Error: $error\n'
        '   StackTrace: $stackTrace',
      );
    },
  );
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // GetIt'ten alıyoruz — artık Provider tree'den değil.
    _authProvider = sl<AuthProvider>();
    _themeProvider = sl<ThemeProvider>();
    _router = createRouter(_authProvider);
    // Tema değiştiğinde MaterialApp'ı yeniden çizdir
    _themeProvider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama uykudan uyandığında veya ekrana döndüğünde CallBloc'u tetikle.
      // Eğer arkaplanda SignalR koptuysa ve bildirim gelmediyse, 
      // REST API üzerinden cevapsız veya bekleyen aramayı burada yakalarız.
      try {
        if (sl.isRegistered<CallBloc>()) {
          final callBloc = sl<CallBloc>();
          callBloc.add(const CallAppResumedSyncRequested());
        }
      } catch (e) {
        // Bloc henüz register edilmemiş olabilir veya hata almış olabilir.
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ları tamamen kaldırdık - GetIt'ten erişilecek veya
    // sayfa seviyesinde wrap edilecek. MaterialApp.router(builder:)
    // bile mount derinliği artırıyor.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: sl<ProfileProvider>()),
      ],
      child: MaterialApp.router(
        title: 'Rider App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeProvider.themeMode,
        routerConfig: _router,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          if (!kDebugMode) return child;
          return Stack(children: [child, const ConnectionStatusOverlay()]);
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
