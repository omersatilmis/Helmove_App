import 'package:dio/dio.dart';
import '../../../../core/error/app_exceptions.dart';
import '../models/feedback_model.dart';
import 'package:path/path.dart' as p;

abstract class FeedbackRemoteDataSource {
  Future<void> sendFeedback(FeedbackModel feedback);
}

class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
  final Dio dio;

  FeedbackRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> sendFeedback(FeedbackModel feedback) async {
    try {
      final formData = FormData.fromMap({
        'message': feedback.message,
        'category': feedback.category,
      });

      if (feedback.screenshot != null) {
        formData.files.add(
          MapEntry(
            'screenshot',
            await MultipartFile.fromFile(
              feedback.screenshot!.path,
              filename: p.basename(feedback.screenshot!.path),
            ),
          ),
        );
      }

      final response = await dio.post('/api/support/feedback', data: formData);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException();
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Ağ Hatası');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
