import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class NotificationGroupParams {
  final int? actorId;
  final int type;
  const NotificationGroupParams({this.actorId, required this.type});
}

class MarkGroupReadUseCase implements UseCase<void, NotificationGroupParams> {
  final NotificationRepository repository;

  MarkGroupReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NotificationGroupParams params) {
    return repository.markGroupAsRead(actorId: params.actorId, type: params.type);
  }
}
