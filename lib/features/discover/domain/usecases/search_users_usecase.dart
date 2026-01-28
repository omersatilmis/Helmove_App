import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../friendship/domain/entities/friend_user_entity.dart';
import '../repositories/discover_repository.dart';

class SearchUsersUseCase
    implements UseCase<List<FriendUserEntity>, SearchUsersParams> {
  final DiscoverRepository repository;

  SearchUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<FriendUserEntity>>> call(
    SearchUsersParams params,
  ) async {
    // Basic validation logic could go here, but UI also handles min 3 chars.
    // We can enforce it here too.
    if (params.query.length < 3) {
      // In a real app we might return a specific Failure, but for now just empty or error?
      // Let's allow it to pass to repository or return empty list immediately to save API call.
      return const Right([]);
    }
    return await repository.searchUsers(
      params.query,
      city: params.city,
      limit: params.limit,
    );
  }
}

class SearchUsersParams extends Equatable {
  final String query;
  final String? city;
  final int limit;

  const SearchUsersParams({required this.query, this.city, this.limit = 20});

  @override
  List<Object?> get props => [query, city, limit];
}
