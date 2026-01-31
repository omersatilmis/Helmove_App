import 'package:dio/dio.dart';
import '../../data/api/interaction_endpoints.dart';
import '../models/comment_model.dart';
import '../../../../../core/error/failures.dart';

abstract class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments({
    required int contentId,
    int page = 1,
  });
  Future<CommentModel> addComment({
    required int contentId,
    required String text,
  });
  Future<void> deleteComment(int commentId);
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final Dio dio;

  CommentRemoteDataSourceImpl(this.dio);

  @override
  Future<List<CommentModel>> getComments({
    required int contentId,
    int page = 1,
  }) async {
    try {
      final response = await dio.get(
        InteractionEndpoints.getComments(contentId),
        queryParameters: {'page': page},
      );

      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);

      return data.map((e) => CommentModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<CommentModel> addComment({
    required int contentId,
    required String text,
  }) async {
    try {
      final response = await dio.post(
        InteractionEndpoints.addComment(contentId),
        data: {'text': text},
      );
      final data = response.data['data'] ?? response.data;
      return CommentModel.fromJson(data);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> deleteComment(int commentId) async {
    try {
      await dio.delete(InteractionEndpoints.deleteComment(commentId));
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
