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
    await _dio.post(ApiEndpoints.likePost(id));
  }
}
