import 'package:dio/dio.dart';
import 'post_endpoints.dart';
import '../models/create_post_request.dart';
import '../models/post_model.dart';

class PostApi {
  final Dio _dio;

  PostApi(this._dio);

  Future<PostModel> createPost(CreatePostRequest request) async {
    final response = await _dio.post(
      ApiEndpoints.createPost,
      data: request.toJson(),
    );
    return PostModel.fromJson(response.data);
  }

  Future<List<PostModel>> getFeed({int page = 1}) async {
    final response = await _dio.get(
      ApiEndpoints.feed,
      queryParameters: {'page': page},
    );
    final List<dynamic> data = response.data is List
        ? response.data
        : (response.data['data'] ?? []);
    return data.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<List<PostModel>> getUserPosts({
    required int userId,
    int page = 1,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.userPosts(userId),
      queryParameters: {'page': page},
    );
    final List<dynamic> data = response.data is List
        ? response.data
        : (response.data['data'] ?? []);
    return data.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<void> deletePost(int id) async {
    await _dio.delete(ApiEndpoints.deletePost(id));
  }

  Future<void> likePost(int id) async {
    // Determine if we need POST or DELETE based on current state?
    // Actually, usually the backend toggle handles it or we have separate endpoints.
    // User request showed: POST /api/likes/{id} and DELETE /api/likes/{id}
    // But existing LikePostUseCase usually toggles.
    // If the Bloc handles logic, we need to know if we are liking or unliking.
    // However, existing PostApi.likePost was just a POST.
    // Let's assume for now it's a POST to toggle or add.
    // Wait, user provided DELETE /api/likes/{contentId} too.
    // We should probably check if we need to pass 'isLiked' to the API or separate methods.
    // For now, I will use POST as the default 'like' action.
    // But if I want to support unlike properly, I might need to change the Bloc to call unlike.

    // Changing to use InteractionEndpoints
    // Note: I need to import InteractionEndpoints.
    await _dio.post('/api/likes/$id');
  }

  Future<void> unlikePost(int id) async {
    await _dio.delete('/api/likes/$id');
  }
}
