import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_group_entity.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<NotificationGroupEntity> groups;
  final List<NotificationEntity> notifications; // SignalR real-time için
  final int unreadCount;
  final bool hasReachedMax;
  final int currentPage;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.groups = const [],
    this.notifications = const [],
    this.unreadCount = 0,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.errorMessage,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationGroupEntity>? groups,
    List<NotificationEntity>? notifications,
    int? unreadCount,
    bool? hasReachedMax,
    int? currentPage,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        groups,
        notifications,
        unreadCount,
        hasReachedMax,
        currentPage,
        errorMessage,
      ];
}
