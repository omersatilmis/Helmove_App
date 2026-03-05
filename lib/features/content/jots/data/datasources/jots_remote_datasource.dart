import '../api/jots_api.dart';
import '../dto/jot_dto.dart';
import '../../../../../core/models/conditional_fetch_result.dart';
import '../../../../../core/models/paged_result.dart';

abstract class JotsRemoteDataSource {
  Future<JotModel> createJot(CreateJotRequest request);
  Future<ConditionalFetchResult<PagedResult<JotModel>>> getFeed({
    int page = 1,
    int limit = 10,
    String? ifNoneMatch,
  });
  Future<PagedResult<JotModel>> getUserJots(
    int userId, {
    int page = 1,
    int limit = 10,
  });
  Future<void> deleteJot(int id);
  Future<void> likeJot(int id);
  Future<void> unlikeJot(int id);
}

class JotsRemoteDataSourceImpl implements JotsRemoteDataSource {
  final JotsApi api;

  JotsRemoteDataSourceImpl(this.api);

  @override
  Future<JotModel> createJot(CreateJotRequest request) {
    return api.createJot(request);
  }

  @override
  Future<ConditionalFetchResult<PagedResult<JotModel>>> getFeed({
    int page = 1,
    int limit = 10,
    String? ifNoneMatch,
  }) {
    return api.getFeed(page: page, limit: limit, ifNoneMatch: ifNoneMatch);
  }

  @override
  Future<PagedResult<JotModel>> getUserJots(
    int userId, {
    int page = 1,
    int limit = 10,
  }) {
    return api.getUserJots(userId, page: page, limit: limit);
  }

  @override
  Future<void> deleteJot(int id) {
    return api.deleteJot(id);
  }

  @override
  Future<void> likeJot(int id) {
    return api.likeJot(id);
  }

  @override
  Future<void> unlikeJot(int id) {
    return api.unlikeJot(id);
  }
}
