import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/unread_count_badge.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';
import '../../domain/entities/notification_group_entity.dart';
import 'package:helmove/features/group_ride/presentation/models/group_ride_args.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_bloc.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_event.dart';
import 'package:helmove/features/voice_session/presentation/bloc/voice_session_state.dart';
import 'package:helmove/features/friendship/presentation/bloc/action/friendship_action_bloc.dart';
import 'package:helmove/features/friendship/presentation/bloc/action/friendship_action_event.dart';
import 'package:helmove/l10n/app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<NotificationsBloc>()
            ..add(const GetGroupedNotificationsEvent())
            ..add(GetUnreadCountEvent()),
        ),
        BlocProvider.value(value: sl<VoiceSessionBloc>()),
        BlocProvider.value(value: sl<FriendshipActionBloc>()),
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
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll * 0.9) {
      final bloc = context.read<NotificationsBloc>();
      if (!bloc.state.hasReachedMax &&
          bloc.state.status != NotificationsStatus.loading) {
        bloc.add(
          GetGroupedNotificationsEvent(page: bloc.state.currentPage + 1),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return BlocListener<VoiceSessionBloc, VoiceSessionState>(
      listenWhen: (p, c) => p.status != c.status || p.message != c.message,
      listener: (context, state) {
        if (state.status == VoiceSessionStatus.error && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(
            l10n.notifications,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          backgroundColor: bg,
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
            if (state.status == NotificationsStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == NotificationsStatus.loading &&
                state.groups.isEmpty) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (state.groups.isEmpty) {
              return _buildEmptyState(l10n, context);
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Theme.of(context).cardColor,
              onRefresh: () async {
                context.read<NotificationsBloc>().add(
                  RefreshGroupedNotificationsEvent(),
                );
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                itemCount: (!state.hasReachedMax &&
                        state.status == NotificationsStatus.loading &&
                        state.currentPage > 1)
                    ? state.groups.length + 1
                    : state.groups.length,
                itemBuilder: (context, index) {
                  if (index >= state.groups.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  return _NotificationGroupTile(
                    key: ValueKey(
                      'group_${state.groups[index].actorId}_${state.groups[index].type}',
                    ),
                    group: state.groups[index],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha(75),
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

// ─────────────────────────────────────────────────────────────────────────────
// GRUP BİLDİRİM SATIRI
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationGroupTile extends StatelessWidget {
  final NotificationGroupEntity group;

  const _NotificationGroupTile({super.key, required this.group});

  // ── Silme ─────────────────────────────────────────────────────────────────

  void _deleteGroup(BuildContext context) {
    context.read<NotificationsBloc>().add(
      DeleteNotificationGroupEvent(
        actorId: group.actorId,
        type: group.type,
        wasUnread: !group.isRead,
      ),
    );
  }

  // ── Okundu + Navigasyon ───────────────────────────────────────────────────

  void _handleTap(BuildContext context) {
    if (!group.isRead) {
      context.read<NotificationsBloc>().add(
        MarkGroupReadEvent(actorId: group.actorId, type: group.type),
      );
    }

    if (group.count > 1) return; // Grup için genel navigate yok

    switch (group.type) {
      case 5: // VoiceSessionInvite
        _handleVoiceSessionNavigation(context);
      case 14: // DirectMessage
        if (group.actorId != null) {
          final username = group.actorUsername ?? '';
          GoRouter.of(context).push(
            '/chat/${group.actorId}?username=$username',
          );
        }
      case 9: // GroupRideInvite
        final rideId = group.rideId;
        if (rideId != null) {
          GoRouter.of(context).push(
            '/communication/group-page/$rideId',
          );
        }
      default:
        if (group.actorId != null && group.actorId! > 0) {
          GoRouter.of(context).push('/profile/${group.actorId}');
        }
    }
  }

  // ── Sesli oturum daveti ──────────────────────────────────────────────────

  Future<void> _handleAcceptVoiceInvite(BuildContext context) async {
    final sessionId = group.sessionId;
    if (sessionId == null) {
      final l10n = AppLocalizations.of(context);
      if (context.mounted && l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.sessionInfoUnavailable)),
        );
      }
      return;
    }

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final voiceBloc = context.read<VoiceSessionBloc>();
    final notifBloc = context.read<NotificationsBloc>();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final currentSession = voiceBloc.state.session;
    if (currentSession != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.leaveRoomTitle),
          content: Text(l10n.alreadyInRideWarning(currentSession.title)),
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
      voiceBloc.add(LeaveVoiceSessionEvent(currentSession.id));
      await Future.delayed(const Duration(milliseconds: 800));
    }

    notifBloc.add(
      DeleteNotificationGroupEvent(
        actorId: group.actorId,
        type: group.type,
        wasUnread: !group.isRead,
      ),
    );

    await _goToGroupPage(
      router: router,
      messenger: messenger,
      voiceBloc: voiceBloc,
      sessionId: sessionId,
      l10n: l10n,
    );
  }

  Future<void> _handleRejectVoiceInvite(BuildContext context) async {
    final sessionId = group.sessionId;
    if (sessionId != null && sessionId > 0) {
      context.read<VoiceSessionBloc>().add(
        RejectVoiceSessionInviteEvent(sessionId),
      );
    }
    _deleteGroup(context);
    final l10n = AppLocalizations.of(context);
    if (context.mounted && l10n != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inviteRejected)),
      );
    }
  }

  Future<void> _handleVoiceSessionNavigation(BuildContext context) async {
    final sessionId = group.sessionId;
    final voiceBloc = context.read<VoiceSessionBloc>();
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final currentSession = voiceBloc.state.session;
    if (currentSession != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.leaveRoomTitle),
          content: Text(l10n.alreadyInRideWarning(currentSession.title)),
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
      voiceBloc.add(LeaveVoiceSessionEvent(currentSession.id));
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (!context.mounted) return;
    await _goToGroupPage(
      router: GoRouter.of(context),
      messenger: ScaffoldMessenger.of(context),
      voiceBloc: voiceBloc,
      sessionId: sessionId,
      l10n: l10n,
    );
  }

  Future<void> _goToGroupPage({
    required GoRouter router,
    required ScaffoldMessengerState messenger,
    required VoiceSessionBloc voiceBloc,
    required int? sessionId,
    required AppLocalizations l10n,
  }) async {
    final rideId = group.rideId;
    final validSession = (sessionId != null && sessionId > 0) ? sessionId : null;
    final validRide = (rideId != null && rideId > 0) ? rideId : null;

    if (validSession == null && validRide == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.idNotFound)));
      return;
    }

    if (validSession != null && !voiceBloc.isClosed) {
      final accepted = await _acceptAndWait(
        voiceBloc: voiceBloc,
        sessionId: validSession,
      );
      if (!accepted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.acceptInviteError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    final args = GroupRideArgs(
      rideId: validRide ?? validSession ?? 0,
      sessionId: validSession,
      groupName: group.groupName ??
          l10n.inviteFromUser(group.actorUsername ?? l10n.friend),
      maxParticipants: 10,
      privacy: 'Private',
      destination: l10n.unknown,
      ridingStyle: l10n.unknown,
      forceBackToCommunication: true,
    );

    router.go('/communication/group-page', extra: args);
  }

  Future<bool> _acceptAndWait({
    required VoiceSessionBloc voiceBloc,
    required int sessionId,
  }) async {
    bool isTarget(VoiceSessionState s) =>
        (s.status == VoiceSessionStatus.inviteAccepted && s.sessionId == sessionId) ||
        (s.status == VoiceSessionStatus.joined &&
            (s.sessionId == sessionId || s.session?.id == sessionId)) ||
        (s.status == VoiceSessionStatus.detailsLoaded && s.session?.id == sessionId) ||
        s.status == VoiceSessionStatus.error;

    if (isTarget(voiceBloc.state)) {
      return voiceBloc.state.status != VoiceSessionStatus.error;
    }

    final future = voiceBloc.stream.firstWhere(isTarget);
    voiceBloc.add(AcceptVoiceSessionInviteEvent(sessionId));

    try {
      final next = await future.timeout(const Duration(seconds: 8));
      return next.status != VoiceSessionStatus.error;
    } catch (_) {
      return true; // optimistic
    }
  }

  // ── Arkadaşlık isteği ────────────────────────────────────────────────────

  void _handleAcceptFriendRequest(BuildContext context) {
    final friendshipId = group.relatedId;
    if (friendshipId != null && friendshipId > 0) {
      context.read<FriendshipActionBloc>().add(
        AcceptFriendRequestEvent(friendshipId: friendshipId),
      );
    }
    _deleteGroup(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arkadaşlık isteği kabul edildi')),
    );
  }

  void _handleRejectFriendRequest(BuildContext context) {
    final friendshipId = group.relatedId;
    if (friendshipId != null && friendshipId > 0) {
      context.read<FriendshipActionBloc>().add(
        RejectFriendRequestEvent(friendshipId: friendshipId),
      );
    }
    _deleteGroup(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arkadaşlık isteği reddedildi')),
    );
  }

  // ── Badge ikonu ──────────────────────────────────────────────────────────

  ({IconData icon, Color color}) get _badge {
    switch (group.type) {
      case 1:  return (icon: Icons.person_add, color: Colors.orange);
      case 2:  return (icon: Icons.person_add, color: Colors.purple);
      case 3:  return (icon: Icons.favorite, color: Colors.red);
      case 4:  return (icon: Icons.chat_bubble, color: Colors.blue);
      case 5:  return (icon: Icons.headset_mic, color: Colors.green);
      case 9:  return (icon: Icons.directions_bike, color: Colors.amber);
      case 14: return (icon: Icons.message, color: Colors.teal);
      default: return (icon: Icons.notifications, color: AppColors.primary);
    }
  }

  // ── Ana içerik metni ─────────────────────────────────────────────────────

  String _displayText(AppLocalizations l10n) {
    if (group.count > 1 && group.actorUsername != null) {
      return '${group.actorUsername} ve ${group.count - 1} kişi daha';
    }
    return group.latestTitle;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final isUnread = !group.isRead;
    final bgColor = isUnread
        ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE3F2FD))
        : Colors.transparent;

    final badge = _badge;

    return Dismissible(
      key: Key('group_${group.actorId}_${group.type}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _deleteGroup(context);
        return true;
      },
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + rozet
                  Stack(
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
                          userId: group.actorId,
                          overrideImageUrl: group.actorProfilePicture,
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: badge.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(badge.icon, size: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // Metin
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
                              if (group.count > 1 && group.actorUsername != null) ...[
                                TextSpan(
                                  text: '${group.actorUsername} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 've ${group.count - 1} kişi daha',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ] else
                                TextSpan(
                                  text: _displayText(l10n),
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              TextSpan(
                                text:
                                    '  ${timeago.format(group.lastActivityAt, locale: Localizations.localeOf(context).languageCode)}',
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
                        // count > 1 ve title farklıysa alt satırda göster
                        if (group.count > 1 && group.latestTitle.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              group.latestTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Okunmamış nokta
                  if (isUnread)
                    UnreadCountBadge(
                      count: group.count,
                      backgroundColor: Colors.red,
                      minWidth: 18,
                      minHeight: 18,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                    ),
                ],
              ),

              // ── Sesli oturum daveti butonları ────────────────────────────
              if (group.type == 5) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _handleAcceptVoiceInvite(context),
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
                      onPressed: () => _handleRejectVoiceInvite(context),
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

              // ── Arkadaşlık isteği butonları ──────────────────────────────
              if (group.type == 1) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _handleAcceptFriendRequest(context),
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
                        'Kabul Et',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _handleRejectFriendRequest(context),
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
      ),
    );
  }
}
