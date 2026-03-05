import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

// Proje importların (Yolların doğru olduğundan emin ol)
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/unread_count_badge.dart';
// AppTextStyles olduğunu varsayıyorum
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../domain/entities/notification_entity.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_avatar.dart';
import 'package:moto_comm_app_1/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_event.dart';
import 'package:moto_comm_app_1/features/voice_session/presentation/bloc/voice_session_state.dart';
// import 'package:moto_comm_app_1/features/communication/domain/entities/group_ride_data.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<NotificationsBloc>()
            ..add(const GetNotificationsEvent())
            ..add(GetUnreadCountEvent()),
        ),
        BlocProvider.value(value: sl<VoiceSessionBloc>()),
      ],
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Timeago Türkçe ayarı (Main'de yaptıysan buraya gerek yok)
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final bloc = context.read<NotificationsBloc>();
      if (!bloc.state.hasReachedMax &&
          bloc.state.status != NotificationsStatus.loading) {
        bloc.add(GetNotificationsEvent(page: bloc.state.currentPage + 1));
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerini alalım
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final surfaceColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);

    return BlocListener<VoiceSessionBloc, VoiceSessionState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == VoiceSessionStatus.error && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Bildirimler',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          backgroundColor: backgroundColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add_check_circle_rounded),
              color: AppColors.primary,
              tooltip: "Hepsini Okundu İşaretle",
              onPressed: () {
                context.read<NotificationsBloc>().add(
                  MarkAllNotificationsReadEvent(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tüm bildirimler okundu.'),
                    backgroundColor: AppColors.darkSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<NotificationsBloc, NotificationsState>(
          listener: (context, state) {
            if (state.status == NotificationsStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Hata oluştu'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            // Loading İlk Açılış
            if (state.status == NotificationsStatus.loading &&
                state.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            // Boş Liste
            if (state.notifications.isEmpty) {
              return _buildEmptyState(context);
            }

            // Gruplandırma Mantığı
            final groupedItems = _groupNotifications(state.notifications);

            // Liste
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: surfaceColor,
              onRefresh: () async {
                context.read<NotificationsBloc>().add(
                  RefreshNotificationsEvent(),
                );
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                // Pagination loader için +1
                itemCount: state.hasReachedMax
                    ? groupedItems.length
                    : groupedItems.length + 1,
                itemBuilder: (context, index) {
                  if (index >= groupedItems.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  final item = groupedItems[index];

                  if (item is String) {
                    // Başlık (Header)
                    return Padding(
                      key: ValueKey('notification_header_$item'),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  } else if (item is NotificationEntity) {
                    // Bildirim Öğesi
                    return _NotificationItemModern(
                      key: ValueKey('notification_item_${item.id}'),
                      notification: item,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Bildirimleri gruplayıp düz bir liste (Header + Item karışık) haline getirir
  List<dynamic> _groupNotifications(List<NotificationEntity> notifications) {
    final groupedList = <dynamic>[];
    if (notifications.isEmpty) return groupedList;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Grupları tutacak geçici map
    final groups = <String, List<NotificationEntity>>{
      'Bugün': [],
      'Dün': [],
      'Bu Hafta': [],
      'Bu Ay': [],
      'Daha Eski': [],
    };

    for (var notification in notifications) {
      final date = notification.createdAt;
      final diff = now.difference(date);

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        groups['Bugün']!.add(notification);
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        groups['Dün']!.add(notification);
      } else if (diff.inDays < 7) {
        groups['Bu Hafta']!.add(notification);
      } else if (diff.inDays < 30) {
        groups['Bu Ay']!.add(notification);
      } else {
        groups['Daha Eski']!.add(notification);
      }
    }

    // Map'ten listeye çevir (Sadece dolu grupları ekle)
    for (var entry in groups.entries) {
      if (entry.value.isNotEmpty) {
        groupedList.add(entry.key); // Başlık
        groupedList.addAll(entry.value); // İçerikler
      }
    }

    return groupedList;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz bildirim yok',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Etkileşimler burada görünecek',
            style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODERN NOTIFICATION TILE
// -----------------------------------------------------------------------------
class _NotificationItemModern extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationItemModern({super.key, required this.notification});

  void _deleteNotification(BuildContext context) {
    context.read<NotificationsBloc>().add(
      DeleteNotificationEvent(notification.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Arka plan rengi (Okunmamışsa hafif renkli)
    final bgColor = isUnread
        ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE3F2FD))
        : Colors.transparent;

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        _deleteNotification(context);
        return true;
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(context),
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOL: Avatar ve İkon Rozeti
              _buildAvatarWithBadge(context),

              const SizedBox(width: 14),

              // ORTA: Metin ve Zaman
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${notification.senderUsername ?? "Misafir"} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: notification.message,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  ${timeago.format(notification.createdAt, locale: 'tr')}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isVoiceInviteKind(notification)) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _handleAcceptInvite(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              minimumSize: const Size(80, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Katıl',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _handleRejectInvite(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              minimumSize: const Size(80, 32),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Reddet',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // SAĞ: Post Önizleme veya Takip Butonu
              _buildTrailingWidget(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context) {
    // 1. Okundu olarak işaretle
    if (!notification.isRead) {
      context.read<NotificationsBloc>().add(
        MarkNotificationReadEvent(notification.id),
      );
    }

    // 2. Navigasyon Mantığı
    if (_isVoiceInviteKind(notification)) {
      _handleVoiceSessionNavigation(context);
      return;
    }
  }

  bool _isVoiceInviteKind(NotificationEntity notification) {
    final msg = notification.message.toLowerCase();
    // 5 = VoiceSessionInvite from Backend Enum usually
    return (notification.type == 'VoiceSessionInvite') ||
        (notification.type == '5') ||
        msg.contains('davet') ||
        msg.contains('sesli');
  }

  Future<void> _handleAcceptInvite(BuildContext context) async {
    final sessionId = notification.sessionId;
    // Eğer voiceSessionId yoksa eski usul sessionId ara (Geriye uyumluluk)
    final effectiveSessionId = sessionId ?? _getLegacySessionId(notification);

    debugPrint("\uD83D\uDD14 [Notification] _handleAcceptInvite Triggered");
    debugPrint(
      "\uD83D\uDD14 [Notification] Raw Data JSON: ${notification.dataJson}",
    );
    debugPrint("\uD83D\uDD14 [Notification] Parsed sessionId: $sessionId");
    debugPrint(
      "\uD83D\uDD14 [Notification] Parsed rideId: ${notification.rideId}",
    );
    debugPrint(
      "\uD83D\uDD14 [Notification] Effective SessionId: $effectiveSessionId",
    );

    if (effectiveSessionId != null) {
      // 1. Gerekli referansları güvene al (widget unmount olmadan önce)
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final voiceBloc = context.read<VoiceSessionBloc>();
      final notifBloc = context.read<NotificationsBloc>();

      // --- Singleton Session Guard: Aktif oturum varsa onay diyalogu göster ---
      final currentActiveSession = voiceBloc.state.activeSession;
      if (currentActiveSession != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Aktif S\u00fcr\u00fc\u015ften Ayr\u0131l'),
            content: Text(
              '"${currentActiveSession.title}" adl\u0131 s\u00fcr\u00fc\u015fte zaten aktifsiniz. '
              'Bu daveti kabul etti\u011finizde mevcut s\u00fcr\u00fc\u015ften ayr\u0131lacaks\u0131n\u0131z. '
              'Devam etmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('\u0130ptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Evet, Ayr\u0131l ve Kat\u0131l'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        // Kullan\u0131c\u0131 onaylad\u0131 - \u00f6nce mevcut oturumdan ayr\u0131l
        voiceBloc.add(LeaveVoiceSessionEvent(currentActiveSession.id));
        // K\u0131sa bir bekleme ile state g\u00fcncellenmesini bekle
        await Future.delayed(const Duration(milliseconds: 800));
      }

      // 2. Bildirimi sil (Optimistik)
      notifBloc.add(DeleteNotificationEvent(notification.id));

      // 3. Gruba Kat\u0131lma \u0130ste\u011fi ve Navigasyon
      await _goToGroupPageSafe(
        router,
        messenger,
        voiceBloc,
        effectiveSessionId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Oturum bilgisine ula\u015f\u0131lamad\u0131."),
        ),
      );
    }
  }

  Future<void> _handleRejectInvite(BuildContext context) async {
    final sessionId =
        notification.sessionId ?? _getLegacySessionId(notification);

    if (sessionId != null && sessionId > 0) {
      context.read<VoiceSessionBloc>().add(
        RejectVoiceSessionInviteEvent(sessionId),
      );
    }

    // Bildirimi sil
    _deleteNotification(context);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Davet reddedildi.')));
    }
  }

  Future<void> _handleVoiceSessionNavigation(BuildContext context) async {
    final sessionId =
        notification.sessionId ?? _getLegacySessionId(notification);
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final voiceBloc = context.read<VoiceSessionBloc>();

    final currentActiveSession = voiceBloc.state.activeSession;
    if (currentActiveSession != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Aktif Sürüşten Ayrıl'),
          content: Text(
            '"${currentActiveSession.title}" adlı sürüşte zaten aktifsiniz. '
            'Bu gruba geçtiğinizde mevcut sürüşten ayrılacaksınız. '
            'Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Evet, Ayrıl ve Geç'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      voiceBloc.add(LeaveVoiceSessionEvent(currentActiveSession.id));
      await Future.delayed(const Duration(milliseconds: 800));
    }
    // SessionId ve rideId validasyonunu ve yönlendirmeyi tek noktada yap
    final fallbackRideId = notification.rideId;
    final validSessionId = (sessionId != null && sessionId > 0)
        ? sessionId
        : null;
    final validRideId = (fallbackRideId != null && fallbackRideId > 0)
        ? fallbackRideId
        : null;
    if (validSessionId == null && validRideId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Oturum veya Sürüş ID bulunamadı.")),
      );
      return;
    }
    // ...burada eski _goToGroupPageSafe içeriği devam eder...
    // ...existing code...
  }

  // Eski tip JSON parse (Geriye uyumluluk için, eğer entity getter null dönerse)
  int? _getLegacySessionId(NotificationEntity notification) {
    return notification.relatedId;
  }

  Future<void> _goToGroupPageSafe(
    GoRouter router,
    ScaffoldMessengerState messenger,
    VoiceSessionBloc voiceBloc,
    int? sessionId,
  ) async {
    final fallbackRideId = notification.rideId;
    final validSessionId = (sessionId != null && sessionId > 0)
        ? sessionId
        : null;
    final validRideId = (fallbackRideId != null && fallbackRideId > 0)
        ? fallbackRideId
        : null;

    if (validSessionId == null && validRideId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Oturum veya Sürüş ID bulunamadı.")),
      );
      return;
    }

    if (validSessionId != null && !voiceBloc.isClosed) {
      final accepted = await _acceptInviteAndWaitResult(
        voiceBloc: voiceBloc,
        sessionId: validSessionId,
      );

      if (!accepted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Sesli oturum daveti kabul edilemedi. Lütfen tekrar deneyin.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        // Continue navigation anyway in case the ride itself exists
      }
    }

    final groupArgs = GroupRideArgs(
      rideId: validRideId ?? validSessionId ?? 0,
      sessionId: validSessionId,
      groupName:
          notification.groupName ??
          "${notification.senderUsername ?? 'Arkadaş'} Daveti",
      maxParticipants: 10,
      privacy: "Private",
      destination: "Bilinmiyor",
      ridingStyle: "Bilinmiyor",
      forceBackToCommunication: true,
    );

    router.go('/communication/group-page', extra: groupArgs);
  }

  Future<bool> _acceptInviteAndWaitResult({
    required VoiceSessionBloc voiceBloc,
    required int sessionId,
  }) async {
    bool isTargetState(VoiceSessionState state) {
      final detailsLoadedForSession =
          state.status == VoiceSessionStatus.detailsLoaded &&
          state.session?.id == sessionId;
      final acceptedForSession =
          state.status == VoiceSessionStatus.inviteAccepted &&
          state.sessionId == sessionId;
      final joinedForSession =
          state.status == VoiceSessionStatus.joined &&
          (state.sessionId == sessionId || state.session?.id == sessionId);

      return acceptedForSession ||
          joinedForSession ||
          detailsLoadedForSession ||
          state.status == VoiceSessionStatus.error;
    }

    // 1. Önce mevcut state'e bak (Event zaten işlenmiş veya devam ediyor olabilir)
    if (isTargetState(voiceBloc.state)) {
      if (voiceBloc.state.status == VoiceSessionStatus.error) return false;
      // Eğer zaten bu oturumdaysak, event atmaya gerek bile kalmayabilir ama yine de sağlamlaştırıyoruz
    }

    // 2. Stream dinlemeyi başlat
    final acceptanceFuture = voiceBloc.stream.firstWhere(
      (state) => isTargetState(state),
    );

    // 3. İsteği gönder
    voiceBloc.add(AcceptVoiceSessionInviteEvent(sessionId));

    try {
      final nextState = await acceptanceFuture.timeout(
        const Duration(seconds: 8),
      );
      return nextState.status != VoiceSessionStatus.error;
    } on Exception {
      // Event kaçırma / geç state güncelleme durumlarında akışı bloklamayalım.
      // Optimistik olarak true dönüyoruz ki yönlendirme gerçekleşsin.
      return true;
    } catch (_) {
      return false;
    }
  }

  // Avatar ve Köşesindeki İkon
  Widget _buildAvatarWithBadge(BuildContext context) {
    IconData badgeIcon = Icons.notifications;
    Color badgeColor = AppColors.primary;

    final msg = notification.message.toLowerCase();

    // 🔥 GELİŞMİŞ ROZET MANTIĞI
    if (msg.contains('beğen')) {
      badgeIcon = Icons.favorite;
      badgeColor = Colors.red;
    } else if (msg.contains('yorum')) {
      badgeIcon = Icons.chat_bubble;
      badgeColor = Colors.blue;
    } else if (msg.contains('takip')) {
      badgeIcon = Icons.person_add;
      badgeColor = Colors.purple;
    } else if (msg.contains('davet') ||
        msg.contains('sesli') ||
        notification.type == '5') {
      // Sesli sohbet daveti
      badgeIcon = Icons.headset_mic; // Veya Icons.phone_in_talk
      badgeColor = Colors.green;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 1,
            ),
          ),
          child: AppAvatar(
            radius: 22,
            userId: notification.senderId,
            overrideImageUrl: notification.senderProfileImage,
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Icon(badgeIcon, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingWidget() {
    if (!notification.isRead) {
      return const UnreadDotBadge(
        color: AppColors.primary,
        margin: EdgeInsets.only(left: 12, top: 12),
      );
    }
    return const SizedBox(width: 0);
  }
}
