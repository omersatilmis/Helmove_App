import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

// Proje importların (Yolların doğru olduğundan emin ol)
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
// AppTextStyles olduğunu varsayıyorum
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../domain/entities/notification_entity.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:moto_comm_app_1/features/communication/domain/entities/group_ride_data.dart';
import 'package:moto_comm_app_1/features/voice_session/domain/repositories/voice_session_repository.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NotificationsBloc>()
        ..add(const GetNotificationsEvent())
        ..add(GetUnreadCountEvent()),
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

    return Scaffold(
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
              itemCount: state.hasReachedMax
                  ? state.notifications.length
                  : state.notifications.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.notifications.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  );
                }

                final notification = state.notifications[index];
                return _NotificationItemModern(notification: notification);
              },
            ),
          );
        },
      ),
    );
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
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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

  const _NotificationItemModern({required this.notification});

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
      onDismissed: (direction) {
        // Silme eventi eklenebilir
        // context.read<NotificationsBloc>().add(DeleteNotificationEvent(notification.id));
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
                          // Zamanı metnin sonuna eklemek de bir stil tercihidir
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
    // Sesli Oturum Daveti Kontrolü
    final msg = notification.message.toLowerCase();

    // Backend'de type string olarak geliyorsa onu kontrol et, yoksa mesaja bak
    bool isVoiceInvite =
        (notification.type == 'VoiceSessionInvite') ||
        (notification.type == '5') ||
        msg.contains('davet') ||
        msg.contains('sesli');

    if (isVoiceInvite) {
      _navigateToVoiceSession(context);
      return;
    }

    // Diğer tipler için buraya ekeleme yapılabilir
  }

  void _navigateToVoiceSession(BuildContext context) {
    try {
      int? sessionId;

      // 1. Durum: relatedId direkt sessionId ise
      if (notification.relatedId != null) {
        sessionId = notification.relatedId;
      }

      // 2. Durum: dataJson içinden sessionId çekme
      if (sessionId == null && notification.dataJson != null) {
        try {
          final data = json.decode(notification.dataJson!);
          if (data is Map && data.containsKey('sessionId')) {
            sessionId = data['sessionId'];
          }
        } catch (e) {
          debugPrint("JSON Parse hatası: $e");
        }
      }

      if (sessionId != null) {
        _goToGroupPage(context, sessionId);
      } else {
        debugPrint("⚠️ Bildirim detayında ID bulunamadı.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Oturum bilgisine ulaşılamadı. (ID Yok)"),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Navigasyon hatası: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bir hata oluştu.")));
    }
  }

  Future<void> _goToGroupPage(BuildContext context, int sessionId) async {
    // Önce daveti kabul et
    try {
      final voiceSessionRepository = sl<VoiceSessionRepository>();
      await voiceSessionRepository.acceptInvitation(sessionId);
      debugPrint('✅ Davet kabul edildi: $sessionId');
    } catch (e) {
      debugPrint('⚠️ Davet kabul hatası (belki zaten kabul edilmiş): $e');
      // Hata olsa bile devam et - belki zaten kabul edilmiş
    }

    // GroupRideData bekliyor sayfa. Oraya sahte bir data ile gidip ID'yi pasliyoruz.
    // GroupPage icinde ID varsa load et mantigini kurmustuk.
    final dummyData = GroupRideData(
      id: sessionId,
      groupName: "${notification.senderUsername ?? 'Arkadaş'} Daveti",
      maxParticipants: 10,
      privacy: "Private",
      destination: "Bilinmiyor",
      ridingStyle: "Bilinmiyor",
    );

    if (!context.mounted) return;

    // go kullanarak tüm stack'i değiştiriyoruz
    context.go('/communication/group-page', extra: dummyData);
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
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                (notification.senderProfileImage != null &&
                        notification.senderProfileImage!.isNotEmpty)
                    ? notification.senderProfileImage!
                    : 'https://i.pravatar.cc/150?u=${notification.senderId ?? notification.id}',
              ),
              fit: BoxFit.cover,
            ),
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
      return Container(
        margin: const EdgeInsets.only(left: 12, top: 12),
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      );
    }
    return const SizedBox(width: 0);
  }
}
