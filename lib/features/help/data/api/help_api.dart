import 'package:dio/dio.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/feedback_dto.dart';
import '../models/report_dto.dart';
import 'help_endpoints.dart';

class HelpApi {
  final Dio _dio;

  HelpApi(this._dio);

  /// Yeni bir rapor oluşturur
  Future<ReportDto> createReport(ReportDto reportDto) async {
    try {
      AppLogger.info("======== CREATE REPORT START ========");
      AppLogger.debug("Request Data: ${reportDto.toJson()}");

      final response = await _dio.post(
        HelpEndpoints.reports,
        data: reportDto.toJson(),
      );

      AppLogger.info("Response Status: ${response.statusCode}");
      AppLogger.debug("Response Data: ${response.data}");
      AppLogger.info("======== CREATE REPORT END ========");

      return ReportDto.fromJson(response.data);
    } on DioException catch (e) {
      _handleDioError(e, "Rapor gönderimi");
      rethrow;
    } catch (e) {
      _handleUnexpectedError(e, "Rapor gönderimi");
      rethrow;
    }
  }

  /// Yeni bir geri bildirim gönderir
  Future<FeedbackDto> sendFeedback(FeedbackDto feedbackDto) async {
    try {
      AppLogger.info("======== SEND FEEDBACK START ========");
      AppLogger.debug("Request Data: ${feedbackDto.toJson()}");

      final response = await _dio.post(
        HelpEndpoints.feedback,
        data: feedbackDto.toJson(),
      );

      AppLogger.info("Response Status: ${response.statusCode}");
      AppLogger.debug("Response Data: ${response.data}");
      AppLogger.info("======== SEND FEEDBACK END ========");

      final responseData = response.data is Map && response.data['data'] != null
          ? response.data['data'] as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return FeedbackDto.fromJson(responseData);
    } on DioException catch (e) {
      _handleDioError(e, "Geri bildirim gönderimi");
      rethrow;
    } catch (e) {
      _handleUnexpectedError(e, "Geri bildirim gönderimi");
      rethrow;
    }
  }

  void _handleDioError(DioException e, String context) {
    AppLogger.error("======== $context ERROR ========");
    AppLogger.error("Status: ${e.response?.statusCode}");
    AppLogger.error("Data: ${e.response?.data}");
    AppLogger.error("Message: ${e.message}");
    AppLogger.error("================================");
  }

  void _handleUnexpectedError(dynamic e, String context) {
    AppLogger.error("======== $context UNEXPECTED ERROR ========");
    AppLogger.error("Error: $e");
    AppLogger.error("=========================================");
  }
}
