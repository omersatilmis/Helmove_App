import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class GetNotificationsEvent extends NotificationsEvent {
  final int page;
  const GetNotificationsEvent({this.page = 1});

  @override
  List<Object> get props => [page];
}

class GetUnreadCountEvent extends NotificationsEvent {}

class MarkNotificationReadEvent extends NotificationsEvent {
  final int id;
  const MarkNotificationReadEvent(this.id);

  @override
  List<Object> get props => [id];
}

class MarkAllNotificationsReadEvent extends NotificationsEvent {}

class RefreshNotificationsEvent extends NotificationsEvent {}
