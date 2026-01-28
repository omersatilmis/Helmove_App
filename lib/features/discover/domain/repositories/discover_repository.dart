import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../friendship/domain/entities/friend_user_entity.dart';

abstract class DiscoverRepository {
  Future<Either<Failure, List<FriendUserEntity>>> searchUsers(
    String query, {
    String? city,
    int limit = 20,
  });
}
