import '../../../friendship/data/dto/friend_user_dto.dart';

import '../api/discover_api.dart';

abstract class DiscoverRemoteDataSource {
  Future<List<FriendUserModel>> searchUsers(
    String query, {
    String? city,
    int limit = 20,
  });
}

class DiscoverRemoteDataSourceImpl implements DiscoverRemoteDataSource {
  final DiscoverApi api;

  DiscoverRemoteDataSourceImpl(this.api);

  @override
  Future<List<FriendUserModel>> searchUsers(
    String query, {
    String? city,
    int limit = 20,
  }) {
    return api.searchUsers(query, city: city, limit: limit);
  }
}
