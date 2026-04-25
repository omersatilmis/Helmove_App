import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/notification_group_entity.dart';
import '../repositories/notification_repository.dart';

class GetGroupedNotificationsUseCase
    implements UseCase<List<NotificationGroupEntity>, int> {
  final NotificationRepository repository;

  GetGroupedNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationGroupEntity>>> call(int page) {
    return repository.getGroupedNotifications(page: page);
  }
}
