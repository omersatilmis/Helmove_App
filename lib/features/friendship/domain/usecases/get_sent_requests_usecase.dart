import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friend_request_entity.dart';
import '../repositories/friendship_repository.dart';

class GetSentRequestsUseCase
    implements UseCase<List<FriendRequestEntity>, NoParams> {
  final FriendshipRepository repository;

  GetSentRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FriendRequestEntity>>> call(
    NoParams params,
  ) async {
    return await repository.getSentRequests();
  }
}
