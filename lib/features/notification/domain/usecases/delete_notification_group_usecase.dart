import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';
import 'mark_group_read_usecase.dart';

class DeleteNotificationGroupUseCase
    implements UseCase<void, NotificationGroupParams> {
  final NotificationRepository repository;

  DeleteNotificationGroupUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NotificationGroupParams params) {
    return repository.deleteGroup(actorId: params.actorId, type: params.type);
  }
}
