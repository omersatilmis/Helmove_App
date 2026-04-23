import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helmove/core/utils/image_url_extensions.dart';

import 'package:helmove/app/bottom_bar.dart';
import 'package:helmove/core/widgets/app_background.dart';
import 'package:helmove/core/di/injection_container.dart' as di;
import 'package:helmove/features/auth/data/datasources/auth_local_data_source.dart'
    as moto_auth;
import 'package:helmove/core/services/app_session.dart';
import 'package:helmove/core/services/home_bootstrap_service.dart';
import 'package:helmove/core/services/home_summary_service.dart';
import 'package:helmove/core/services/message_signalr_service.dart';
import 'package:helmove/core/services/signalr_service.dart';
import 'package:helmove/core/services/call_listener_service.dart';
import 'package:helmove/core/theme/text_styles.dart';
import 'package:helmove/core/usecases/usecase.dart';
import 'package:helmove/core/widgets/unread_count_badge.dart';
import 'package:helmove/features/auth/presentation/providers/auth_provider.dart';
import 'package:helmove/features/content/posts/data/cache/post_feed_cache.dart';
import 'package:helmove/features/content/posts/presentation/bloc/posts_bloc.dart';
import 'package:helmove/features/content/posts/presentation/bloc/posts_event.dart';
import 'package:helmove/features/homepage/presentation/widgets/home_feed_tabs.dart';
import 'package:helmove/features/messages/domain/usecases/get_unread_count_usecase.dart'
    as msg_unread;
import 'package:helmove/features/profile/presentation/providers/profile_provider.dart';
import 'package:helmove/features/notification/domain/usecases/get_unread_count_usecase.dart'
    as notif_unread;
import 'package:helmove/l10n/app_localizations.dart';

class HomePageWithDrawer extends StatefulWidget {
  const HomePageWithDrawer({super.key});

  @override
  State<HomePageWithDrawer> createState() => _HomePageWithDrawerState();
}

class _HomePageWithDrawerState extends State<HomePageWithDrawer> {
  static const Duration _countFetchCooldown = Duration(milliseconds: 1200);

  String? _visorMessage;
  late final ValueNotifier<_HomeTopbarCounts> _topbarCountsNotifier;
  late final ValueNotifier<_HomeIdentityFallback> _identityFallbackNotifier;
  bool _isBadgeRefreshInFlight = false;
  bool _isBootstrapInFlight = false;
  bool _isHomeBootstrapSettled = false;
  bool _realtimeStreamsBound = false;
  late final Future<void> _bootstrapFuture;
  Future<void>? _realtimeInitFuture;
  DateTime? _lastBadgeRefreshAt;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _readPayloadSubscription;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _topbarCountsNotifier = ValueNotifier(const _HomeTopbarCounts());
    _identityFallbackNotifier = ValueNotifier(const _HomeIdentityFallback());

    _bootstrapFuture = _bootstrapHomeData();
    _realtimeInitFuture = _initializeRealtimeAfterBootstrap();

    // 🔥 Profil verilerini yükle (Önce cache'den gelir, sonra backend'den güncellenir)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _visorMessage = _getRandomMotoMessage();
        });
        context.read<ProfileProvider>().loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _readPayloadSubscription?.cancel();
    _notificationSubscription?.cancel();
    _topbarCountsNotifier.dispose();
    _identityFallbackNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshTopbarCounters({bool force = false}) async {
    if (_isBadgeRefreshInFlight) {
      return;
    }

    final now = DateTime.now();
    final lastFetch = _lastBadgeRefreshAt;
    if (!force &&
        lastFetch != null &&
        now.difference(lastFetch) < _countFetchCooldown) {
      return;
    }

    _isBadgeRefreshInFlight = true;
    _lastBadgeRefreshAt = now;

    try {
      final summaryService = GetIt.I<HomeSummaryService>();
      final summary = await summaryService.getSummary();

      if (summary != null) {
        _setTopbarCounts(
          messageCount: summary.unreadMessageCount,
          notificationCount: summary.unreadNotificationCount,
        );
        return;
      }

      final getUnreadCount = GetIt.I<msg_unread.GetUnreadCountUseCase>();
      final useCase = GetIt.I<notif_unread.GetUnreadCountUseCase>();

      final unreadMessagesFuture = getUnreadCount();
      final unreadNotificationsFuture = useCase(NoParams());

      final unreadMessages = await unreadMessagesFuture;
      final unreadNotificationsEither = await unreadNotificationsFuture;

      var unreadNotifications = _topbarCountsNotifier.value.notificationCount;
      unreadNotificationsEither.fold((_) {}, (count) {
        unreadNotifications = count;
      });

      _setTopbarCounts(
        messageCount: unreadMessages,
        notificationCount: unreadNotifications,
      );
    } catch (e) {
      // Intentionally ignored.
    } finally {
      _isBadgeRefreshInFlight = false;
    }
  }

  Future<void> _bootstrapHomeData() async {
    if (_isBootstrapInFlight) {
      return;
    }
    
    debugPrint('🏠 Starting Home Bootstrap...');
    _isBootstrapInFlight = true;

    try {
      final bootstrapService = GetIt.I<HomeBootstrapService>();
      final bootstrap = await bootstrapService.getHomeBootstrap(limit: 10);

      if (bootstrap != null) {
        debugPrint('✅ Home Bootstrap successful: ${bootstrap.feed.items.length} posts');
        _identityFallbackNotifier.value = _HomeIdentityFallback(
          firstName: bootstrap.user?.firstName,
          lastName: bootstrap.user?.lastName,
          profileImageUrl: bootstrap.user?.profilePictureUrl,
        );

        // Cache'i güncelle (Profile tarafına gitmeden önce de telefonda saklanması için)
        try {
          if (bootstrap.user != null) {
            final localAuth = GetIt.I<moto_auth.AuthLocalDataSource>();
            await localAuth.saveFirstName(bootstrap.user?.firstName);
            await localAuth.saveLastName(bootstrap.user?.lastName);
            if (bootstrap.user?.email != null) {
              await localAuth.saveEmail(bootstrap.user!.email!);
            }
            await localAuth.saveProfileImageUrl(
              bootstrap.user?.profilePictureUrl,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error updating local auth cache during bootstrap: $e');
        }

        _setTopbarCounts(
          messageCount: bootstrap.unreadMessageCount,
          notificationCount: bootstrap.unreadNotificationCount,
        );

        if (bootstrap.feed.items.isNotEmpty) {
          final postFeedCache = GetIt.I<PostFeedCache>();
          final appSession = GetIt.I<AppSession>();
          await postFeedCache.writeFirstPage(
            userId: appSession.currentUserId,
            posts: bootstrap.feed.items,
            hasNextPage: bootstrap.feed.hasNextPage,
            limit: 10,
          );

          try {
            final postsBloc = GetIt.I<PostsBloc>();
            postsBloc.add(
              SeedInitialFeedEvent(
                posts: bootstrap.feed.items,
                hasNextPage: bootstrap.feed.hasNextPage,
              ),
            );
          } catch (e) {
            debugPrint('⚠️ Error seeding PostsBloc: $e');
          }
        }
      } else {
        debugPrint('⚠️ Home Bootstrap returned null (Service caught 404 or other error)');
      }
    } catch (e) {
      debugPrint('❌ Home Bootstrap CRITICAL error: $e');
    } finally {
      _isBootstrapInFlight = false;
      if (mounted && !_isHomeBootstrapSettled) {
        setState(() {
          _isHomeBootstrapSettled = true;
        });
      } else {
        _isHomeBootstrapSettled = true;
      }
      debugPrint('🏠 Home Bootstrap settled.');
    }
  }

  Future<void> _initializeRealtimeAfterBootstrap() async {
    await _bootstrapFuture;
    if (!mounted || _realtimeStreamsBound) {
      return;
    }

    SignalRService? signalRService;
    try {
      signalRService = GetIt.I<SignalRService>();
      signalRService.enableStartupConnection();
      await signalRService.init();
    } catch (_) {
      // Intentionally ignored.
    }

    MessageSignalRService? messageService;
    try {
      messageService = GetIt.I<MessageSignalRService>();
      await messageService.init();
    } catch (_) {
      // Intentionally ignored.
    }

    try {
      await di.initDeferredFeatures();
      GetIt.I<CallListenerService>().start();
    } catch (_) {
      // Intentionally ignored.
    }

    if (!mounted) {
      return;
    }

    _bindRealtimeStreams(
      messageService: messageService,
      signalRService: signalRService,
    );
  }

  void _bindRealtimeStreams({
    MessageSignalRService? messageService,
    SignalRService? signalRService,
  }) {
    if (_realtimeStreamsBound) {
      return;
    }
    _realtimeStreamsBound = true;

    final resolvedMessageService =
        messageService ?? GetIt.I<MessageSignalRService>();
    final resolvedSignalRService = signalRService ?? GetIt.I<SignalRService>();

    _messageSubscription = resolvedMessageService.onDirectMessageReceived
        .listen((message) {
          final handled = _applyRealtimeCountsFromPayload(message);
          if (!handled) {
            _refreshTopbarCounters();
          }
        });

    _readPayloadSubscription = resolvedMessageService.onMessagesReadPayload
        .listen((payload) {
          final handled = _applyRealtimeCountsFromPayload(payload);
          if (!handled) {
            _refreshTopbarCounters();
          }
        });

    _notificationSubscription = resolvedSignalRService
        .notificationReceivedStream
        .listen((payload) {
          final handled = _applyRealtimeCountsFromPayload(payload);
          if (!handled) {
            _refreshTopbarCounters();
          }
        });
  }

  Future<void> _ensureBootstrapAndRealtimeReady() async {
    await _bootstrapFuture;
    _realtimeInitFuture ??= _initializeRealtimeAfterBootstrap();
    await _realtimeInitFuture;
  }

  bool _applyRealtimeCountsFromPayload(dynamic payload) {
    final map = _toMap(payload);
    if (map == null) {
      return false;
    }

    final nested = _toMap(map['data']) ?? _toMap(map['payload']) ?? map;
    final messageCount = _readIntFromMap(nested, const [
      'unreadMessageCount',
      'unreadMessages',
      'messageUnreadCount',
      'messagesUnreadCount',
    ]);
    final notificationCount = _readIntFromMap(nested, const [
      'unreadNotificationCount',
      'unreadNotifications',
      'notificationUnreadCount',
      'notificationsUnreadCount',
    ]);

    if (messageCount == null && notificationCount == null) {
      return false;
    }

    final current = _topbarCountsNotifier.value;
    _setTopbarCounts(
      messageCount: messageCount ?? current.messageCount,
      notificationCount: notificationCount ?? current.notificationCount,
    );
    return true;
  }

  Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty || text == 'null') {
        return null;
      }
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int? _readIntFromMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  void _setTopbarCounts({
    required int messageCount,
    required int notificationCount,
  }) {
    if (!mounted) {
      return;
    }
    final current = _topbarCountsNotifier.value;
    if (current.messageCount == messageCount &&
        current.notificationCount == notificationCount) {
      return;
    }
    _topbarCountsNotifier.value = _HomeTopbarCounts(
      messageCount: messageCount,
      notificationCount: notificationCount,
    );
  }

  Future<void> _openMessages() async {
    await _ensureBootstrapAndRealtimeReady();
    await di.initDeferredFeatures();
    if (!mounted) {
      return;
    }
    await context.push('/messages');
    if (!mounted) {
      return;
    }
    await _refreshTopbarCounters(force: true);
  }

  Future<void> _openNotifications() async {
    await _ensureBootstrapAndRealtimeReady();
    await di.initDeferredFeatures();
    if (!mounted) {
      return;
    }
    await context.push('/notifications');
    if (!mounted) {
      return;
    }
    await _refreshTopbarCounters(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // Fallback UI to avoid complete blank screen if localization is not yet ready
      return const AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;


    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _HomeTopAppBar(
          visorMessage: _visorMessage ?? '',
          countsListenable: _topbarCountsNotifier,
          identityFallbackListenable: _identityFallbackNotifier,
          onOpenDrawer: () {
            final provider = context.read<ProfileProvider>();
            if (provider.profile == null && !provider.isLoading) {
              provider.loadProfile();
            }
            mainScaffoldKey.currentState?.openDrawer();
          },
          onMessagesTap: () {
            unawaited(_openMessages());
          },
          onNotificationsTap: () {
            unawaited(_openNotifications());
          },
          greetingBuilder: _getGreeting,
          l10n: l10n,
          isDark: isDark,
          colorScheme: colorScheme,
        ),
        body: _isHomeBootstrapSettled
            ? const HomeFeedTabs()
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return '';
    if (hour >= 5 && hour < 11) return '🌅 ${l10n.goodMorning}';
    if (hour >= 11 && hour < 17) return '☀️ ${l10n.goodDay}';
    if (hour >= 17 && hour < 21) return '🌇 ${l10n.goodEvening}';
    if (hour >= 21 && hour <= 23) return '🌃 ${l10n.goodNight}';
    return '🌌 ${l10n.rideCarefully}';
  }

  String _getRandomMotoMessage() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return '';
    final messages = <String>[
      l10n.motoMessage1,
      l10n.motoMessage2,
      l10n.motoMessage3,
      l10n.motoMessage4,
      l10n.motoMessage5,
      l10n.motoMessage6,
      l10n.motoMessage7,
      l10n.motoMessage8,
      l10n.motoMessage9,
      l10n.motoMessage10,
      l10n.motoMessage11,
      l10n.motoMessage12,
      l10n.motoMessage13,
      l10n.motoMessage14,
      l10n.motoMessage15,
      l10n.motoMessage16,
      l10n.motoMessage17,
      l10n.motoMessage18,
      l10n.motoMessage19,
      l10n.motoMessage20,
      l10n.motoMessage21,
      l10n.motoMessage22,
    ];
    return (messages..shuffle()).first;
  }
}

class _HomeTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String visorMessage;
  final ValueNotifier<_HomeTopbarCounts> countsListenable;
  final ValueNotifier<_HomeIdentityFallback> identityFallbackListenable;
  final VoidCallback onOpenDrawer;
  final VoidCallback onMessagesTap;
  final VoidCallback onNotificationsTap;
  final String Function() greetingBuilder;
  final AppLocalizations l10n;
  final bool isDark;
  final ColorScheme colorScheme;

  const _HomeTopAppBar({
    required this.visorMessage,
    required this.countsListenable,
    required this.identityFallbackListenable,
    required this.onOpenDrawer,
    required this.onMessagesTap,
    required this.onNotificationsTap,
    required this.greetingBuilder,
    required this.l10n,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 42);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 300,
      leading: GestureDetector(
        onTap: onOpenDrawer,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 16.0),
          child: ValueListenableBuilder<_HomeIdentityFallback>(
            valueListenable: identityFallbackListenable,
            builder: (context, fallback, _) {
              return Selector2<
                ProfileProvider,
                AuthProvider,
                _HomeIdentityView
              >(
                selector: (_, profileProvider, authProvider) =>
                    _HomeIdentityView.fromProviders(
                      profileProvider: profileProvider,
                      authProvider: authProvider,
                      fallback: fallback,
                      l10n: l10n,
                    ),
                builder: (context, identity, _) {
                  final imageProvider =
                      (identity.profileImageUrl != null &&
                          identity.profileImageUrl!.trim().isNotEmpty)
                      ? CachedNetworkImageProvider(identity.profileImageUrl!.toAbsoluteImageUrl())
                          : const AssetImage('assets/icons/ic_profile.png')
                             as ImageProvider;

                  return Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundImage: imageProvider),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingBuilder(),
                              style: AppTextStyles.regular.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            Text(
                              identity.displayName,
                              style: AppTextStyles.bold.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      actions: [
        ValueListenableBuilder<_HomeTopbarCounts>(
          valueListenable: countsListenable,
          builder: (context, counts, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/icons/ic_message.png',
                        width: 26,
                        height: 26,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: onMessagesTap,
                    ),
                    if (counts.messageCount > 0)
                      Positioned(
                        right: 7,
                        top: 8,
                        child: UnreadCountBadge.messageIcon(
                          count: counts.messageCount,
                          scheme: theme.colorScheme,
                        ),
                      ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/icons/ic_bell.png',
                        width: 26,
                        height: 26,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: onNotificationsTap,
                    ),
                    if (counts.notificationCount > 0)
                      Positioned(
                        right: 7,
                        top: 8,
                        child: UnreadCountBadge.notificationIcon(
                          count: counts.notificationCount,
                          scheme: theme.colorScheme,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(42),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.08)
                : colorScheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.08 : 0.03,
                ),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  visorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTopbarCounts {
  final int messageCount;
  final int notificationCount;

  const _HomeTopbarCounts({this.messageCount = 0, this.notificationCount = 0});
}

class _HomeIdentityFallback {
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;

  const _HomeIdentityFallback({
    this.firstName,
    this.lastName,
    this.profileImageUrl,
  });
}

class _HomeIdentityView {
  final String displayName;
  final String? profileImageUrl;
  final String? userBio;

  const _HomeIdentityView({
    required this.displayName,
    this.profileImageUrl,
    this.userBio,
  });

  factory _HomeIdentityView.fromProviders({
    required ProfileProvider profileProvider,
    required AuthProvider authProvider,
    required _HomeIdentityFallback fallback,
    required AppLocalizations l10n,
  }) {
    final cachedUser = authProvider.currentUser;
    final firstName = profileProvider.firstName.isNotEmpty
        ? profileProvider.firstName
        : (cachedUser?.firstName ?? fallback.firstName ?? '');
    final lastName = profileProvider.lastName.isNotEmpty
        ? profileProvider.lastName
        : (cachedUser?.lastName ?? fallback.lastName ?? '');

    final composedName = '$firstName $lastName'.trim();
    final displayName = composedName.isNotEmpty
        ? composedName
        : (cachedUser?.fullName ?? cachedUser?.username ?? l10n.user);

    final profileImageUrl =
        profileProvider.profileImageUrl ??
        cachedUser?.profileImageUrl ??
        fallback.profileImageUrl;

    return _HomeIdentityView(
      displayName: displayName,
      profileImageUrl: profileImageUrl,
      userBio: l10n.rideCarefully,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _HomeIdentityView &&
        other.displayName == displayName &&
        other.profileImageUrl == profileImageUrl;
  }

  @override
  int get hashCode => Object.hash(displayName, profileImageUrl);
}
