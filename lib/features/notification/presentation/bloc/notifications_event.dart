import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

// ── Grouped (yeni) ──────────────────────────────────────────────────────────
class GetGroupedNotificationsEvent extends NotificationsEvent {
  final int page;
  const GetGroupedNotificationsEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class RefreshGroupedNotificationsEvent extends NotificationsEvent {}

class MarkGroupReadEvent extends NotificationsEvent {
  final int? actorId;
  final int type;
  const MarkGroupReadEvent({this.actorId, required this.type});

  @override
  List<Object?> get props => [actorId, type];
}

class DeleteNotificationGroupEvent extends NotificationsEvent {
  final int? actorId;
  final int type;
  final bool wasUnread;
  const DeleteNotificationGroupEvent({
    this.actorId,
    required this.type,
    this.wasUnread = false,
  });

  @override
  List<Object?> get props => [actorId, type, wasUnread];
}

// ── Ortak ───────────────────────────────────────────────────────────────────
class GetUnreadCountEvent extends NotificationsEvent {}

class MarkAllNotificationsReadEvent extends NotificationsEvent {}

class NotificationReceivedEvent extends NotificationsEvent {
  final dynamic notification;
  const NotificationReceivedEvent(this.notification);

  @override
  List<Object?> get props => [notification];
}

// ── Eski (geriye dönük uyumluluk için korunuyor) ─────────────────────────
class GetNotificationsEvent extends NotificationsEvent {
  final int page;
  const GetNotificationsEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class MarkNotificationReadEvent extends NotificationsEvent {
  final int id;
  const MarkNotificationReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshNotificationsEvent extends NotificationsEvent {}

class DeleteNotificationEvent extends NotificationsEvent {
  final int id;
  const DeleteNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}
