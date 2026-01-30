import '../api/post_api.dart';
import '../models/create_post_request.dart';
import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<PostModel> createPost(CreatePostRequest request);
  Future<List<PostModel>> getFeed({int page = 1});
  Future<List<PostModel>> getUserPosts({required int userId, int page = 1});
  Future<void> deletePost(int id);
  Future<void> likePost(int id);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final PostApi api;

  PostRemoteDataSourceImpl(this.api);

  @override
  Future<PostModel> createPost(CreatePostRequest request) {
    return api.createPost(request);
  }

  @override
  Future<List<PostModel>> getFeed({int page = 1}) {
    return api.getFeed(page: page);
  }

  @override
  Future<List<PostModel>> getUserPosts({required int userId, int page = 1}) {
    return api.getUserPosts(userId: userId, page: page);
  }

  @override
  Future<void> deletePost(int id) {
    return api.deletePost(id);
  }

  @override
  Future<void> likePost(int id) {
    return api.likePost(id);
  }
}
