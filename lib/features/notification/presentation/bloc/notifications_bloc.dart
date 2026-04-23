import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/signalr_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotifications;
  final GetUnreadCountUseCase getUnreadCount;
  final MarkNotificationReadUseCase markNotificationRead;
  final MarkAllNotificationsReadUseCase markAllNotificationsRead;
  final DeleteNotificationUseCase deleteNotification;
  final SignalRService signalRService;

  StreamSubscription? _notificationSubscription;
  final Set<int> _inFlightPages = <int>{};

  NotificationsBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
    required this.deleteNotification,
    required this.signalRService,
  }) : super(const NotificationsState()) {
    on<GetNotificationsEvent>(_onGetNotifications);
    on<GetUnreadCountEvent>(_onGetUnreadCount);
    on<MarkNotificationReadEvent>(_onMarkNotificationRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllNotificationsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
    on<NotificationReceivedEvent>(_onNotificationReceived);

    // Subscribe to SignalR Stream and store the subscription
    _notificationSubscription = signalRService.notificationReceivedStream
        .listen((notification) {
          if (!isClosed) {
            add(NotificationReceivedEvent(notification));
          }
        });
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }

  void _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<NotificationsState> emit,
  ) {
    try {
      final raw = event.notification;
      if (raw is! Map) {
        return;
      }
      final data = raw.map((key, value) => MapEntry(key.toString(), value));

      // Güvenli Parsing Helper
      int parseInt(dynamic value) {
        if (value == null) return 0; // ID required
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      int? parseNullableInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        return null;
      }

      String? normalizeDataJson(dynamic value) {
        if (value == null) return null;
        if (value is String) {
          final text = value.trim();
          if (text.isEmpty || text == 'null') return null;
          return text;
        }

        try {
          return jsonEncode(value);
        } catch (_) {
          final text = value.toString().trim();
          if (text.isEmpty || text == 'null') return null;
          return text;
        }
      }

      final newNotification = NotificationEntity(
        id: parseInt(data['id']),
        title: data['title']?.toString() ?? '',
        message: data['body']?.toString() ?? '',
        isRead: false,
        createdAt: data['createdAt'] != null
            ? DateTime.parse(data['createdAt'].toString())
            : DateTime.now(),
        type: data['type']?.toString(),
        relatedId: parseNullableInt(data['relatedId']),
        senderId: parseNullableInt(data['actorId']),
        senderUsername: data['actorUsername']?.toString(),
        senderProfileImage: data['actorProfilePictureUrl']?.toString(),
        dataJson: normalizeDataJson(data['dataJson']),
      );

      final alreadyExists = state.notifications.any(
        (n) => n.id == newNotification.id,
      );
      if (alreadyExists) {
        return;
      }

      // Add to top of list and increment unread count
      emit(
        state.copyWith(
          notifications: [newNotification, ...state.notifications],
          unreadCount: state.unreadCount + 1,
        ),
      );
    } catch (e, stack) {
      debugPrint('❌ Notification Parse Error: $e');
      debugPrint(stack.toString());
      // Hata durumunda UI'a bilgi verelim ama state'i bozmayalım
      emit(state.copyWith(errorMessage: 'Bildirim alınırken hata: $e'));
    }
  }

  Future<void> _onGetNotifications(
    GetNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_inFlightPages.contains(event.page)) {
      return;
    }

    try {
      _inFlightPages.add(event.page);

      if (state.hasReachedMax && event.page != 1) return;

      // Drop stale/duplicate page requests (e.g., repeated page=2 triggers on fast scroll).
      if (event.page != 1 && event.page <= state.currentPage) {
        return;
      }

      if (event.page == 1) {
        emit(state.copyWith(status: NotificationsStatus.loading));
      }

      final result = await getNotifications(event.page);

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: NotificationsStatus.failure,
            errorMessage: 'Bildirimler yüklenemedi',
          ),
        ),
        (notifications) {
          final mergedList = event.page == 1
              ? notifications
              : [...state.notifications, ...notifications];
          final updatedList = _dedupeNotificationsById(mergedList);

          emit(
            state.copyWith(
              status: NotificationsStatus.success,
              notifications: updatedList,
              hasReachedMax: notifications.isEmpty,
              currentPage: event.page,
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      // Catch any unexpected exceptions to prevent crash
      debugPrint('❌ NotificationsBloc Error: $e');
      debugPrint('Stack trace: $stackTrace');
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: 'Beklenmeyen hata: $e',
        ),
      );
    } finally {
      _inFlightPages.remove(event.page);
    }
  }

  Future<void> _onGetUnreadCount(
    GetUnreadCountEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await getUnreadCount(NoParams());
    result.fold(
      (failure) => null, // Hata olsa bile sessiz kalabiliriz
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  Future<void> _onMarkNotificationRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    NotificationEntity? target;
    for (final notification in state.notifications) {
      if (notification.id == event.id) {
        target = notification;
        break;
      }
    }

    final updatedNotifications = state.notifications
        .map(
          (n) => n.id == event.id
              ? NotificationEntity(
                  id: n.id,
                  title: n.title,
                  message: n.message,
                  isRead: true,
                  createdAt: n.createdAt,
                  type: n.type,
                  relatedId: n.relatedId,
                  senderId: n.senderId,
                  senderUsername: n.senderUsername,
                  senderProfileImage: n.senderProfileImage,
                  dataJson: n.dataJson,
                )
              : n,
        )
        .toList();

    final shouldDecrease =
        target != null && !target.isRead && state.unreadCount > 0;
    emit(
      state.copyWith(
        notifications: updatedNotifications,
        unreadCount: shouldDecrease ? state.unreadCount - 1 : state.unreadCount,
      ),
    );

    await markNotificationRead(event.id);
  }

  Future<void> _onMarkAllNotificationsRead(
    MarkAllNotificationsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // Optimistik: Hepsi okundu kabul et, sayıyı sıfırla
    emit(state.copyWith(unreadCount: 0));
    final result = await markAllNotificationsRead(NoParams());

    if (isClosed) return;

    result.fold((failure) => null, (_) {
      if (!isClosed) {
        add(const GetNotificationsEvent(page: 1));
      }
    });
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    // 1. Optimistic Update
    final previousNotifications = List<NotificationEntity>.from(
      state.notifications,
    );
    NotificationEntity? deletedNotification;
    for (final notification in state.notifications) {
      if (notification.id == event.id) {
        deletedNotification = notification;
        break;
      }
    }
    final updatedList = state.notifications
        .where((n) => n.id != event.id)
        .toList();

    final nextUnread =
        (deletedNotification != null &&
            !deletedNotification.isRead &&
            state.unreadCount > 0)
        ? state.unreadCount - 1
        : state.unreadCount;

    emit(state.copyWith(notifications: updatedList, unreadCount: nextUnread));

    // 2. API Call
    try {
      final result = await deleteNotification(event.id);

      // Guard: bloc may have been closed during the API call (page navigated away)
      if (isClosed) return;

      // 3. Rollback on Failure
      result.fold(
        (failure) {
          if (!isClosed) {
            final rollbackUnread = previousNotifications
                .where((n) => !n.isRead)
                .length;
            emit(
              state.copyWith(
                notifications: previousNotifications,
                unreadCount: rollbackUnread,
                errorMessage: 'Bildirim silinemedi',
              ),
            );
          }
        },
        (_) {
          if (!isClosed) {
            add(GetUnreadCountEvent());
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationsBloc] _onDeleteNotification error: $e');
      // Don't rethrow — prevent crash if bloc was closed during API call
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NotificationsStatus.initial,
        notifications: [],
        hasReachedMax: false,
        currentPage: 1,
      ),
    );
    add(const GetNotificationsEvent(page: 1));
    add(GetUnreadCountEvent());
  }

  List<NotificationEntity> _dedupeNotificationsById(
    List<NotificationEntity> items,
  ) {
    final seenIds = <int>{};
    final result = <NotificationEntity>[];
    for (final item in items) {
      if (seenIds.contains(item.id)) continue;
      seenIds.add(item.id);
      result.add(item);
    }
    return result;
  }
}
