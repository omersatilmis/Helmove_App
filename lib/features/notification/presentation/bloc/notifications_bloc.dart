import 'package:bloc/bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotifications;
  final GetUnreadCountUseCase getUnreadCount;
  final MarkNotificationReadUseCase markNotificationRead;
  final MarkAllNotificationsReadUseCase markAllNotificationsRead;

  NotificationsBloc({
    required this.getNotifications,
    required this.getUnreadCount,
    required this.markNotificationRead,
    required this.markAllNotificationsRead,
  }) : super(const NotificationsState()) {
    on<GetNotificationsEvent>(_onGetNotifications);
    on<GetUnreadCountEvent>(_onGetUnreadCount);
    on<MarkNotificationReadEvent>(_onMarkNotificationRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllNotificationsRead);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
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
      print('❌ NotificationsBloc Error: $e');
      print('Stack trace: $stackTrace');
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
    // Optimistik Update
    // Optimistik Update
    // updatedNotifications değişkenini kaldırdık çünkü kullanılmıyordu.
    // İleride Entity'e copyWith eklenirse o zaman kullanılabilir.

    // Basitçe unread count'u 1 azaltabiliriz
    if (state.unreadCount > 0) {
      emit(state.copyWith(unreadCount: state.unreadCount - 1));
    }

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
