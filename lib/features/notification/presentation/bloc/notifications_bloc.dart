import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/signalr_service.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_grouped_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/mark_group_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/delete_notification_group_usecase.dart';
import '../../domain/entities/notification_group_entity.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotifications;
  final GetGroupedNotificationsUseCase getGroupedNotifications;
  final GetUnreadCountUseCase getUnreadCount;
  final MarkNotificationReadUseCase markNotificationRead;
  final MarkAllNotificationsReadUseCase markAllNotificationsRead;
  final MarkGroupReadUseCase markGroupRead;
  final DeleteNotificationUseCase deleteNotification;
  final DeleteNotificationGroupUseCase deleteNotificationGroup;
  final SignalRService signalRService;

  StreamSubscription? _notificationSubscription;
  final Set<int> _inFlightPages = <int>{};

  NotificationsBloc({
    required this.getNotifications,
    required this.getGroupedNotifications,
    required this.getUnreadCount,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
    required this.markGroupRead,
    required this.deleteNotification,
    required this.deleteNotificationGroup,
    required this.signalRService,
  }) : super(const NotificationsState()) {
    on<GetGroupedNotificationsEvent>(_onGetGroupedNotifications);
    on<RefreshGroupedNotificationsEvent>(_onRefreshGroupedNotifications);
    on<MarkGroupReadEvent>(_onMarkGroupRead);
    on<DeleteNotificationGroupEvent>(_onDeleteNotificationGroup);
    on<GetUnreadCountEvent>(_onGetUnreadCount);
    on<MarkAllNotificationsReadEvent>(_onMarkAllNotificationsRead);
    on<NotificationReceivedEvent>(_onNotificationReceived);
    // Eski event'ler (geriye dönük uyumluluk)
    on<GetNotificationsEvent>(_onGetNotifications);
    on<MarkNotificationReadEvent>(_onMarkNotificationRead);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
    on<DeleteNotificationEvent>(_onDeleteNotification);

    _notificationSubscription = signalRService.notificationReceivedStream
        .listen((notification) {
          if (!isClosed) add(NotificationReceivedEvent(notification));
        });
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }

  // ── Gruplu bildirimler ──────────────────────────────────────────────────

  Future<void> _onGetGroupedNotifications(
    GetGroupedNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_inFlightPages.contains(event.page)) return;
    if (state.hasReachedMax && event.page != 1) return;
    if (event.page != 1 && event.page <= state.currentPage) return;

    try {
      _inFlightPages.add(event.page);

      if (event.page == 1) {
        emit(state.copyWith(status: NotificationsStatus.loading));
      }

      final result = await getGroupedNotifications(event.page);

      result.fold(
        (failure) => emit(state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: 'Bildirimler yüklenemedi',
        )),
        (groups) {
          final merged = event.page == 1
              ? groups
              : [...state.groups, ...groups];
          final deduped = _dedupeGroups(merged);
          emit(state.copyWith(
            status: NotificationsStatus.success,
            groups: deduped,
            hasReachedMax: groups.isEmpty,
            currentPage: event.page,
          ));
        },
      );
    } catch (e) {
      debugPrint('❌ NotificationsBloc._onGetGroupedNotifications: $e');
      emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: 'Beklenmeyen hata: $e',
      ));
    } finally {
      _inFlightPages.remove(event.page);
    }
  }

  Future<void> _onRefreshGroupedNotifications(
    RefreshGroupedNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      status: NotificationsStatus.initial,
      groups: [],
      hasReachedMax: false,
      currentPage: 1,
    ));
    add(const GetGroupedNotificationsEvent(page: 1));
    add(GetUnreadCountEvent());
  }

  Future<void> _onMarkGroupRead(
    MarkGroupReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistik: grubu hemen okundu yap
    final updated = state.groups.map((g) {
      if (g.actorId == event.actorId && g.type == event.type) {
        return g.copyWithRead();
      }
      return g;
    }).toList();

    final wasUnread = state.groups.any(
      (g) => g.actorId == event.actorId && g.type == event.type && !g.isRead,
    );
    final nextUnread = wasUnread && state.unreadCount > 0
        ? state.unreadCount - 1
        : state.unreadCount;

    emit(state.copyWith(groups: updated, unreadCount: nextUnread));

    await markGroupRead(
      NotificationGroupParams(actorId: event.actorId, type: event.type),
    );
  }

  Future<void> _onDeleteNotificationGroup(
    DeleteNotificationGroupEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final previous = List<NotificationGroupEntity>.from(state.groups);
    final filtered = state.groups
        .where((g) => !(g.actorId == event.actorId && g.type == event.type))
        .toList();

    final nextUnread = event.wasUnread && state.unreadCount > 0
        ? state.unreadCount - 1
        : state.unreadCount;

    emit(state.copyWith(groups: filtered, unreadCount: nextUnread));

    try {
      final result = await deleteNotificationGroup(
        NotificationGroupParams(actorId: event.actorId, type: event.type),
      );

      if (isClosed) return;

      result.fold(
        (failure) {
          if (!isClosed) {
            emit(state.copyWith(
              groups: previous,
              unreadCount: state.unreadCount,
              errorMessage: 'Bildirim silinemedi',
            ));
          }
        },
        (_) {
          if (!isClosed) add(GetUnreadCountEvent());
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationsBloc] _onDeleteNotificationGroup: $e');
    }
  }

  // ── Ortak ───────────────────────────────────────────────────────────────

  Future<void> _onGetUnreadCount(
    GetUnreadCountEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await getUnreadCount(NoParams());
    result.fold(
      (failure) => null,
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  Future<void> _onMarkAllNotificationsRead(
    MarkAllNotificationsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(
      unreadCount: 0,
      groups: state.groups.map((g) => g.copyWithRead()).toList(),
    ));
    final result = await markAllNotificationsRead(NoParams());
    if (isClosed) return;
    result.fold(
      (failure) => null,
      (_) {
        if (!isClosed) add(const GetGroupedNotificationsEvent(page: 1));
      },
    );
  }

  // SignalR real-time: unread sayısını artır ve grupları yenile
  void _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<NotificationsState> emit,
  ) {
    emit(state.copyWith(unreadCount: state.unreadCount + 1));
    if (!isClosed) add(const GetGroupedNotificationsEvent(page: 1));
  }

  // ── Eski event handler'lar (geriye dönük uyumluluk) ──────────────────────

  Future<void> _onGetNotifications(
    GetNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    add(GetGroupedNotificationsEvent(page: event.page));
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    await markNotificationRead(event.id);
  }

  Future<void> _onRefreshNotifications(
    RefreshNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    add(RefreshGroupedNotificationsEvent());
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    await deleteNotification(event.id);
  }

  // ── Yardımcı ────────────────────────────────────────────────────────────

  List<NotificationGroupEntity> _dedupeGroups(
    List<NotificationGroupEntity> items,
  ) {
    final seen = <String>{};
    final result = <NotificationGroupEntity>[];
    for (final item in items) {
      final key = '${item.actorId}_${item.type}';
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(item);
    }
    return result;
  }
}
