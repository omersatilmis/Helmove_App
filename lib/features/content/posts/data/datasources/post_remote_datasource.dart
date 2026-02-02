import '../api/post_api.dart';
import '../models/create_post_request.dart';
import '../models/post_model.dart';
import '../../../../../core/models/paged_result.dart';

abstract class PostRemoteDataSource {
  Future<PostModel> createPost(CreatePostRequest request);
  Future<PagedResult<PostModel>> getFeed({int page = 1, int limit = 10});
  Future<PagedResult<PostModel>> getUserPosts({
    required int userId,
    int page = 1,
    int limit = 10,
  });
  Future<void> deletePost(int id);
  Future<void> likePost(int id);
  Future<void> unlikePost(int id);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final PostApi api;

  PostRemoteDataSourceImpl(this.api);

  @override
  Future<PostModel> createPost(CreatePostRequest request) {
    return api.createPost(request);
  }

  @override
  Future<PagedResult<PostModel>> getFeed({int page = 1, int limit = 10}) {
    return api.getFeed(page: page, limit: limit);
  }

  @override
  Future<PagedResult<PostModel>> getUserPosts({
    required int userId,
    int page = 1,
    int limit = 10,
  }) {
    return api.getUserPosts(userId: userId, page: page, limit: limit);
  }

  @override
  Future<void> deletePost(int id) {
    return api.deletePost(id);
  }

  @override
  Future<void> likePost(int id) {
    return api.likePost(id);
  }

  @override
  Future<void> unlikePost(int id) {
    return api.unlikePost(id);
  }
}
