import '../../domain/entities/feedback_entity.dart';
import '../../domain/entities/report_entity.dart';

abstract class HelpRepository {
  Future<ReportEntity> createReport(ReportEntity report);
  Future<FeedbackEntity> sendFeedback(FeedbackEntity feedback);
}
