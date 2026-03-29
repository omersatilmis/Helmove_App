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
import 'package:helmove/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_event.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_state.dart';
import 'package:helmove/l10n/app_localizations.dart';

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
    // Timeago localized messages
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    timeago.setLocaleMessages('en', timeago.EnMessages());
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

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
            l10n.notifications,
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
              tooltip: l10n.markAllAsRead,
              onPressed: () {
                context.read<NotificationsBloc>().add(
                  MarkAllNotificationsReadEvent(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.allNotificationsRead),
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
                  content: Text(state.errorMessage ?? l10n.errorOccurred),
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
              return _buildEmptyState(l10n, context);
            }

            // Gruplandırma Mantığı
            final groupedItems = _groupNotifications(state.notifications, l10n);

            // Liste
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).cardColor,
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
  List<dynamic> _groupNotifications(
    List<NotificationEntity> notifications,
    AppLocalizations l10n,
  ) {
    final groupedList = <dynamic>[];
    if (notifications.isEmpty) return groupedList;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Grupları tutacak geçici map
    final groups = <String, List<NotificationEntity>>{
      l10n.today: [],
      l10n.yesterday: [],
      l10n.thisWeek: [],
      l10n.thisMonth: [],
      l10n.older: [],
    };

    for (var notification in notifications) {
      final date = notification.createdAt;
      final diff = now.difference(date);

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        groups[l10n.today]!.add(notification);
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        groups[l10n.yesterday]!.add(notification);
      } else if (diff.inDays < 7) {
        groups[l10n.thisWeek]!.add(notification);
      } else if (diff.inDays < 30) {
        groups[l10n.thisMonth]!.add(notification);
      } else {
        groups[l10n.older]!.add(notification);
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

  Widget _buildEmptyState(AppLocalizations l10n, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withAlpha(75),
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
            l10n.noNotificationsYet,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.interactionsWillShowUp,
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
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

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
                                '${notification.senderUsername ?? l10n.guest} ',
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
                                '  ${timeago.format(notification.createdAt, locale: Localizations.localeOf(context).languageCode)}',
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
                            child: Text(
                              l10n.join,
                              style: const TextStyle(
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
                              l10n.decline,
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
      final currentActiveSession = voiceBloc.state.session;
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;

      if (currentActiveSession != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.leaveRoomTitle),
            content: Text(
              l10n.alreadyInRideWarning(currentActiveSession.title),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.leaveAndJoin),
              ),
            ],
          ),
        );

        if (confirmed != true) return;

        // Kullanıcı onayladı - önce mevcut oturumdan ayrıl
        voiceBloc.add(LeaveVoiceSessionEvent(currentActiveSession.id));
        // Kısa bir bekleme ile state güncellenmesini bekle
        await Future.delayed(const Duration(milliseconds: 800));
      }

      // 2. Bildirimi sil (Optimistik)
      notifBloc.add(DeleteNotificationEvent(notification.id));

      // 3. Gruba Katılma İsteği ve Navigasyon
      await _goToGroupPageSafe(
        router,
        messenger,
        voiceBloc,
        effectiveSessionId,
        l10n,
      );
    } else {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.sessionInfoUnavailable),
            ),
          );
        }
      }
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
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.inviteRejected)));
      }
    }
  }

  Future<void> _handleVoiceSessionNavigation(BuildContext context) async {
    final sessionId =
        notification.sessionId ?? _getLegacySessionId(notification);
    final voiceBloc = context.read<VoiceSessionBloc>();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final currentActiveSession = voiceBloc.state.session;
    if (currentActiveSession != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.leaveRoomTitle),
          content: Text(
            l10n.alreadyInRideWarning(currentActiveSession.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.leaveAndJoin),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.idNotFound)),
        );
      }
      return;
    }

    if (validSessionId != null && !voiceBloc.isClosed) {
      final accepted = await _acceptInviteAndWaitResult(
        voiceBloc: voiceBloc,
        sessionId: validSessionId,
      );

      if (!accepted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.acceptInviteError,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        // Continue navigation anyway in case the ride itself exists
      }
    }

    final groupArgs = GroupRideArgs(
      rideId: validRideId ?? validSessionId ?? 0,
      sessionId: validSessionId,
      groupName: notification.groupName ??
          l10n.inviteFromUser(notification.senderUsername ?? l10n.friend),
      maxParticipants: 10,
      privacy: "Private",
      destination: l10n.unknown,
      ridingStyle: l10n.unknown,
      forceBackToCommunication: true,
    );

    if (context.mounted) {
      GoRouter.of(context).go('/communication/group-page', extra: groupArgs);
    }
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
    AppLocalizations l10n,
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
        SnackBar(content: Text(l10n.idNotFound)),
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
          SnackBar(
            content: Text(
              l10n.acceptInviteError,
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
          l10n.inviteFromUser(notification.senderUsername ?? l10n.friend),
      maxParticipants: 10,
      privacy: "Private",
      destination: l10n.unknown,
      ridingStyle: l10n.unknown,
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
