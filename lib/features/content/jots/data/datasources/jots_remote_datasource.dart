import '../api/jots_api.dart';
import '../dto/jot_dto.dart';

abstract class JotsRemoteDataSource {
  Future<JotModel> createJot(CreateJotRequest request);
  Future<List<JotModel>> getFeed({int page = 1});
  Future<List<JotModel>> getUserJots(int userId, {int page = 1});
  Future<void> deleteJot(int id);
}

class JotsRemoteDataSourceImpl implements JotsRemoteDataSource {
  final JotsApi api;

  JotsRemoteDataSourceImpl(this.api);

  @override
  Future<JotModel> createJot(CreateJotRequest request) {
    return api.createJot(request);
  }

  @override
  Future<List<JotModel>> getFeed({int page = 1}) {
    return api.getFeed(page: page);
  }

  @override
  Future<List<JotModel>> getUserJots(int userId, {int page = 1}) {
    return api.getUserJots(userId, page: page);
  }

  @override
  Future<void> deleteJot(int id) {
    return api.deleteJot(id);
  }
}
