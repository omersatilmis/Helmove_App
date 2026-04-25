import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../entities/notification_group_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
  });
  Future<Either<Failure, List<NotificationGroupEntity>>> getGroupedNotifications({
    int page = 1,
  });
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, void>> markAsRead(int id);
  Future<Either<Failure, void>> markAllAsRead();
  Future<Either<Failure, void>> deleteNotification(int id);
  Future<Either<Failure, void>> markGroupAsRead({int? actorId, required int type});
  Future<Either<Failure, void>> deleteGroup({int? actorId, required int type});
}
