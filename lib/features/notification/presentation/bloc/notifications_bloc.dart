import 'dart:async';
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
      final data = event.notification as Map<String, dynamic>;

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

      final newNotification = NotificationEntity(
        id: parseInt(data['id']),
        title: data['title']?.toString() ?? '',
        message: data['body']?.toString() ?? '',
        isRead: false,
        createdAt: data['createdAt'] != null
            ? DateTime.parse(data['createdAt'].toString())
            : DateTime.now(),
        type: data['type']?.toString(),
        senderId: parseNullableInt(data['actorId']),
        senderUsername: data['actorUsername']?.toString(),
        senderProfileImage: data['actorProfilePictureUrl']?.toString(),
        dataJson: data['dataJson']?.toString(),
      );

      final alreadyExists = state.notifications.any((n) => n.id == newNotification.id);
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
    try {
      if (state.hasReachedMax && event.page != 1) return;

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
          final updatedList = event.page == 1
              ? notifications
              : [...state.notifications, ...notifications];
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

    final shouldDecrease = target != null && !target.isRead && state.unreadCount > 0;
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

    result.fold(
      (failure) => null, // Geri almakla uğraşmıyoruz şimdilik
      (_) => add(const GetNotificationsEvent(page: 1)), // Listeyi tazeleyelim
    );
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
        (deletedNotification != null && !deletedNotification.isRead && state.unreadCount > 0)
            ? state.unreadCount - 1
            : state.unreadCount;

    emit(state.copyWith(notifications: updatedList, unreadCount: nextUnread));

    // 2. API Call
    final result = await deleteNotification(event.id);

    // 3. Rollback on Failure
    result.fold(
      (failure) {
        final rollbackUnread = previousNotifications.where((n) => !n.isRead).length;
        emit(
          state.copyWith(
            notifications: previousNotifications,
            unreadCount: rollbackUnread,
            errorMessage: 'Bildirim silinemedi',
          ),
        );
      },
      (_) {
        add(GetUnreadCountEvent());
      },
    );
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
}
