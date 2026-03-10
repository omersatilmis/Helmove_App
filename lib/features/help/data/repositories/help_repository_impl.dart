import '../../domain/entities/feedback_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/help_repository.dart';
import '../datasources/help_remote_data_source.dart';
import '../models/feedback_dto.dart';
import '../models/report_dto.dart';

class HelpRepositoryImpl implements HelpRepository {
  final HelpRemoteDataSource remoteDataSource;

  HelpRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ReportEntity> createReport(ReportEntity report) async {
    // Entity -> DTO dönüşümü (Raporlama için)
    final dto = ReportDto(
      targetId: report.targetId,
      targetType: report.targetType.value,
      category: report.category.value,
      description: report.description,
      status: report.status.value,
    );

    final resultDto = await remoteDataSource.createReport(dto);
    return resultDto.toEntity();
  }

  @override
  Future<FeedbackEntity> sendFeedback(FeedbackEntity feedback) async {
    // Entity -> DTO dönüşümü (Geri bildirim için)
    final dto = FeedbackDto(
      category: feedback.category.value,
      title: feedback.title,
      content: feedback.content,
      status: feedback.status.value,
    );

    final resultDto = await remoteDataSource.sendFeedback(dto);
    return resultDto.toEntity();
  }
}
