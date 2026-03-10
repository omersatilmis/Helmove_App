import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/report_entity.dart';
import '../repositories/help_repository.dart';

class CreateReportUseCase implements UseCase<ReportEntity, ReportEntity> {
  final HelpRepository repository;

  CreateReportUseCase(this.repository);

  @override
  Future<Either<Failure, ReportEntity>> call(ReportEntity params) async {
    try {
      final result = await repository.createReport(params);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
