import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:moto_comm_app_1/core/services/message_signalr_service.dart';
import 'package:moto_comm_app_1/core/services/signalr_service.dart';
import 'package:moto_comm_app_1/features/messages/domain/usecases/get_conversations_usecase.dart';
import 'package:moto_comm_app_1/core/usecases/usecase.dart';
import 'package:moto_comm_app_1/core/widgets/unread_count_badge.dart';
import 'package:moto_comm_app_1/features/notification/domain/usecases/get_unread_count_usecase.dart'
    as notif_unread;

// 🔥 DİKKAT: Drawer'ı dışarıdan kontrol etmek için bu import şart!
import 'package:moto_comm_app_1/app/bottom_bar.dart';
import 'package:moto_comm_app_1/core/theme/text_styles.dart';
import 'package:moto_comm_app_1/features/profile/presentation/providers/profile_provider.dart';
import 'package:moto_comm_app_1/core/services/permissions_service.dart' as di;
import 'package:moto_comm_app_1/core/services/callkit_incoming_service.dart';
import 'package:moto_comm_app_1/features/homepage/presentation/widgets/home_feed_tabs.dart';

class HomePageWithDrawer extends StatefulWidget {
  const HomePageWithDrawer({super.key});

  @override
  State<HomePageWithDrawer> createState() => _HomePageWithDrawerState();
}

class _HomePageWithDrawerState extends State<HomePageWithDrawer>
    with WidgetsBindingObserver {
  late String _visorMessage;
  int _unreadConversationCount = 0;
  int _unreadNotificationCount = 0;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _readSubscription;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // [NEW] Observer
    _visorMessage = _getRandomMotoMessage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });

    _checkUnreadConversations();
    _checkUnreadNotifications();

    // Startup Permissions Request
    _requestStartupPermissions();

    // SignalR üzerinden gelen mesajları dinle
    try {
      final messageService = GetIt.I<MessageSignalRService>();
      // Stream yapısı sayesinde diğer dinleyicileri (örn: Chat sayfası) bozmadan dinliyoruz
      _messageSubscription = messageService.onDirectMessageReceived.listen((
        message,
      ) {
        _checkUnreadConversations();
      });

      // Mesajlar okunduğunda (MessagesRead) sayıyı tekrar kontrol et
      _readSubscription = messageService.onMessagesRead.listen((_) {
        _checkUnreadConversations();
      });
    } catch (e) {
      debugPrint("MessageSignalRService bağlantı hatası: $e");
    }

    // Genel bildirimleri dinle (SignalRService)
    try {
      final signalRService = GetIt.I<SignalRService>();
      _notificationSubscription = signalRService.notificationReceivedStream
          .listen((_) {
            _checkUnreadNotifications();
          });
    } catch (e) {
      debugPrint("SignalRService bağlantı hatası: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Kullanıcı ayarlardan dönmüş olabilir, izinleri tekrar kontrol et
      _requestStartupPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // [NEW] Remove observer
    _messageSubscription?.cancel();
    _readSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkUnreadConversations() async {
    try {
      final getConversations = GetIt.I<GetConversationsUseCase>();
      final conversations = await getConversations();
      final count = conversations.where((c) => c.unreadCount > 0).length;
      if (mounted) {
        setState(() {
          _unreadConversationCount = count;
        });
      }
    } catch (e) {
      debugPrint("Okunmamış sohbet sayısı alınamadı: $e");
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final useCase = GetIt.I<notif_unread.GetUnreadCountUseCase>();
      final result = await useCase(NoParams());
      result.fold((_) {}, (count) {
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      });
    } catch (e) {
      debugPrint("Okunmamış bildirim sayısı alınamadı: $e");
    }
  }

  Future<void> _requestStartupPermissions() async {
    try {
      final permissionsService = GetIt.I<di.PermissionsService>();
      final granted = await permissionsService.requestAllStartupPermissions();

      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tam sesli sohbet deneyimi için Mikrofon, Bluetooth, Konum ve Arama izinleri gereklidir.',
            ),
            padding: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ayarlar',
              textColor: Colors.white,
              onPressed: () {
                di.PermissionsService.openSettings();
              },
            ),
          ),
        );
      } else if (granted && mounted) {
        // [NEW] Eğer izinler verildiyse uyarıyı kaldır
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // [NEW] CallKit ek izinlerini (Full Intent vb.) iste
        try {
          final callKitService = GetIt.I<CallKitIncomingService>();
          await callKitService.requestPermissions();
        } catch (e) {
          debugPrint("CallKit permissions error: $e");
        }
      }
    } catch (e) {
      debugPrint("Startup permissions error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final firstName = profileProvider.firstName;
    final lastName = profileProvider.lastName;
    final profileImage =
        profileProvider.profileImageUrl ?? 'https://i.pravatar.cc/150?img=11';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Dinamik arka plan gradyanı
    final backgroundGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A100A), // Koyu modda hafif kırmızımsı üst
              Color(0xFF12100E),
            ],
            stops: [0.0, 0.4],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.surface,
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 300,
          leading: GestureDetector(
            onTap: () {
              mainScaffoldKey.currentState?.openDrawer();
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(profileImage),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: AppTextStyles.regular.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        Text(
                          "$firstName $lastName",
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
              ),
            ),
          ),
          actions: [
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
                  onPressed: () {
                    context.push('/messages').then((_) {
                      _checkUnreadConversations();
                    });
                  },
                ),
                if (_unreadConversationCount > 0)
                  Positioned(
                    right: 7,
                    top: 8,
                    child: UnreadCountBadge.messageIcon(
                      count: _unreadConversationCount,
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
                  onPressed: () {
                    context.push('/notifications').then((_) {
                      _checkUnreadNotifications();
                    });
                  },
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 7,
                    top: 8,
                    child: UnreadCountBadge.notificationIcon(
                      count: _unreadNotificationCount,
                      scheme: theme.colorScheme,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],

          // --- VİZÖR MESAJI ALANI (Glow Efekti Buraya Eklendi) ---
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // Glow (Parlama) Efekti: BoxShadow ile neon bir hava veriyoruz
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
                      _visorMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.9,
                        ),
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
        ),
        body: const HomeFeedTabs(),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return "🌅 Günaydın";
    if (hour >= 11 && hour < 17) return "☀️ İyi günler";
    if (hour >= 17 && hour < 21) return "🌇 İyi akşamlar";
    if (hour >= 21 && hour <= 23) return "🌃 İyi geceler";
    return "🌌 Dikkatli sür";
  }

  String _getRandomMotoMessage() {
    final List<String> messages = [
      "Depon dolu, virajın bol olsun! 🏍️",
      "Bakkala bile ekipmansız gitmiyoruz, değil mi? 🤨",
      "Benzin kaç para oldu haberin var mı usta? ⛽",
      "Vizörün temiz, yolun açık olsun. ✨",
      "Tekerine taş, gözüne yaş değmesin. ✨",
      "Motoru tozlu gördüm, bir ara yıka istersen... 🤔",
      "Motor biraz tozlanmış… demek ki güzel anılar birikmiş 😏",
      "Ekipman tamam mı? Cool görünmekten önce sağlam dönelim eve 😎",
      "Tekerin düz bassın da rota neresi olursa olsun 😌",
      "Vizör temiz, kafanın karışık olabilir, dert etme, biz varız ✨",
      "Ekipmanına önem ver, bizim için kıymetlisin 😎",
      "Motorun sesi moralinden yüksek olsun 🎵🏍️",
      "Vites mi o? Ben ayak ucuyla piyano çalıyorum sanmıştım. 🎹",
      "Tekerin yere bassın ama aklın havada kalmasın. ✌️",
      "O egzoz sesiyle anca mahalleye iftar vaktini haber verirsin. 🔊",
      "Virajda motoru yatıramıyorsan söyle, yan ayaklığı açalım. 📉",
      "Kaskı kola takınca koruma sağlamıyor, 'Pro' kardeş. 🦾",
      "Ekipman hayat kurtarır, kaskı takmayı unutma!",
      "Asfalt ağlıyor be, yavaş biraz! 💨",
      "Yine hangi rotanın hayalini kuruyorsun? 🤔",
      "Motorcu selamını vermeyi unutma!",
      "Hava yağmurlu diye motoru çıkarmadın mı? Şeker misin sen? 🍭",
    ];
    return (messages..shuffle()).first;
  }
}
