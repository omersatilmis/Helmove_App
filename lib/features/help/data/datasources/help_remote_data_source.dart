import '../api/help_api.dart';
import '../models/feedback_dto.dart';
import '../models/report_dto.dart';

abstract class HelpRemoteDataSource {
  Future<ReportDto> createReport(ReportDto reportDto);
  Future<FeedbackDto> sendFeedback(FeedbackDto feedbackDto);
}

class HelpRemoteDataSourceImpl implements HelpRemoteDataSource {
  final HelpApi api;

  HelpRemoteDataSourceImpl({required this.api});

  @override
  Future<ReportDto> createReport(ReportDto reportDto) async {
    return await api.createReport(reportDto);
  }

  @override
  Future<FeedbackDto> sendFeedback(FeedbackDto feedbackDto) async {
    return await api.sendFeedback(feedbackDto);
  }
}
