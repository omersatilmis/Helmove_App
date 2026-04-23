import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';

import 'package:helmove/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:helmove/firebase_options.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helmove/app/app_router.dart';
import 'package:helmove/core/theme/app_theme.dart';
import 'package:helmove/core/theme/theme_provider.dart';
import 'package:helmove/core/localization/language_provider.dart';
import 'package:helmove/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';

import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/auth/domain/repositories/auth_repository.dart';
import 'package:helmove/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:helmove/core/services/app_session.dart';
import 'package:helmove/core/services/subscription_service.dart';
import 'package:helmove/core/network/auth_bootstrap_gate.dart';
import 'package:helmove/core/presentation/widgets/connection_status_overlay.dart';
import 'package:helmove/core/utils/app_bloc_observer.dart';
import 'package:helmove/core/services/deep_link_store.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:helmove/features/call/presentation/bloc/call_bloc.dart';
import 'package:helmove/features/call/presentation/bloc/call_event.dart';
import 'package:helmove/features/presence/services/presence_controller.dart';
import 'package:helmove/features/presence/utils/timeago_setup.dart';
import 'package:helmove/features/intercom/domain/intercom_engine.dart';
import 'package:helmove/features/intercom/domain/intercom_models.dart';
import 'package:helmove/core/services/app_background_service.dart';

void main() async {
  // ── runZonedGuarded: Catches ALL unhandled async errors globally ──
  // This is the SAFETY NET that prevents invisible crashes from
  // bloc.dart:231 rethrow escaping to the microtask loop.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ── Firebase Initialization ──
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        // Setup FCM background handler
        await NotificationService.setupBackgroundHandler();
      } catch (e) {
        debugPrint('🔴 [Firebase] Initialization failed: $e');
      }

      // ⚠️ GLOBAL ERROR HANDLING (Synchronous & Platform)
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('🔴 [FlutterError] ${details.exceptionAsString()}');
        // If crashlytics or similar service exists, log it here
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('🔴 [PlatformDispatcher] Async error: $error\n$stack');
        return true;
      };

      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('Warning: .env could not be loaded: $e');
      }

      // Register global BlocObserver so ALL bloc errors are logged
      Bloc.observer = AppBlocObserver();

      // 1. Dependency Injection Kurulumu
      await initCore();

      final prefs = await SharedPreferences.getInstance();
      final hasShownOnboarding = prefs.getBool('onboarding_shown') ?? false;

      // 1.1 Auth bootstrap: runApp oncesi token'i storage'dan yukle
      final authBootstrapGate = sl<AuthBootstrapGate>();
      String? bootstrappedToken;
      try {
        final authLocalDataSource = sl<AuthLocalDataSource>();
        final shouldRemember = await authLocalDataSource.getRememberMe();

        if (!shouldRemember) {
          await authLocalDataSource.clearAuthData();
          sl<AppSession>().clearSession();
        } else {
          bootstrappedToken = await authLocalDataSource.getToken();
        }
        if (bootstrappedToken != null && bootstrappedToken.isNotEmpty) {
          final persistedUser = await sl<AuthRepository>().getPersistedUser();
          if (persistedUser != null) {
            sl<AppSession>().updateSession(
              currentUserId: persistedUser.id,
              currentUser: persistedUser,
              token: persistedUser.token,
            );

            // 💳 Sync RevenueCat Session
            try {
              if (sl.isRegistered<SubscriptionService>()) {
                await sl<SubscriptionService>().logIn(
                  persistedUser.id.toString(),
                );
                debugPrint('✅ RevenueCat session synced: ${persistedUser.id}');
              }
            } catch (e) {
              debugPrint('❌ RevenueCat session sync failed: $e');
            }
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

      // 2. Date Formatting + Timeago Türkçe locale
      await initializeDateFormatting('tr_TR', null);
      setupTimeagoLocales();

      // 3. Root widget
      runApp(MyApp(hasShownOnboarding: hasShownOnboarding));
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
  final bool hasShownOnboarding;
  const MyApp({super.key, required this.hasShownOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final AuthProvider _authProvider;
  late final ThemeProvider _themeProvider;
  late final LanguageProvider _languageProvider;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // GetIt'ten alıyoruz — artık Provider tree'den değil.
    _authProvider = sl<AuthProvider>();
    _themeProvider = sl<ThemeProvider>();
    _languageProvider = sl<LanguageProvider>();
    _router = createRouter(_authProvider, widget.hasShownOnboarding);
    // Tema ve Dil değiştiğinde MaterialApp'ı yeniden çizdir
    _themeProvider.addListener(_onThemeChanged);
    _languageProvider.addListener(_onLanguageChanged);
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleIncomingUri(initial);
      }
    } catch (_) {
      // Best-effort deep link handling.
    }

    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(uri);
    }, onError: (_) {});
  }

  void _handleIncomingUri(Uri uri) {
    if (uri.scheme != 'helmove') {
      return;
    }

    if (uri.host == 'share') {
      DeepLinkStore.instance.push(uri);
      _router.go('/map');
      return;
    }

    // OTP akışında deep link yok — yönlendirme butonla yapılıyor.
    // Eski 'reset-password' deep link'i artık desteklenmiyor.
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        if (sl.isRegistered<CallBloc>()) {
          final callBloc = sl<CallBloc>();
          callBloc.add(const CallAppResumedSyncRequested());
        }
      } catch (_) {}

      _notifyPresenceForeground();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _notifyPresenceBackground();
    }

    // Sesli iletişim: engine'e lifecycle bildir + Android'de foreground service garantile
    _notifyIntercomLifecycle(state);
  }

  void _notifyIntercomLifecycle(AppLifecycleState state) {
    try {
      if (!sl.isRegistered<IntercomEngine>()) return;
      final engine = sl<IntercomEngine>();

      final IntercomLifecycleState engineState;
      switch (state) {
        case AppLifecycleState.resumed:
          engineState = IntercomLifecycleState.resumed;
        case AppLifecycleState.inactive:
          engineState = IntercomLifecycleState.inactive;
        case AppLifecycleState.paused:
          engineState = IntercomLifecycleState.paused;
        case AppLifecycleState.detached:
          engineState = IntercomLifecycleState.detached;
        case AppLifecycleState.hidden:
          engineState = IntercomLifecycleState.hidden;
      }

      unawaited(engine.onLifecycleChanged(engineState));

      // Android: ekran kapanınca / arkaplanda aktif görüşme varsa foreground service garantile
      if (Platform.isAndroid &&
          (state == AppLifecycleState.paused ||
              state == AppLifecycleState.inactive)) {
        if (engine.snapshot.transport != IntercomTransport.none) {
          unawaited(AppBackgroundService.start());
        }
      }
    } catch (_) {}
  }

  void _notifyPresenceForeground() {
    try {
      if (sl.isRegistered<PresenceController>()) {
        sl<PresenceController>().onForeground();
      }
    } catch (_) {}
  }

  void _notifyPresenceBackground() {
    try {
      if (sl.isRegistered<PresenceController>()) {
        sl<PresenceController>().onBackground();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeProvider.removeListener(_onThemeChanged);
    _languageProvider.removeListener(_onLanguageChanged);
    _linkSub?.cancel();
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
        ChangeNotifierProvider.value(value: _languageProvider),
        ChangeNotifierProvider.value(value: sl<ProfileProvider>()),
      ],
      child: MaterialApp.router(
        title: 'Helmove',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeProvider.themeMode,
        locale: _languageProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
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
