import 'package:equatable/equatable.dart';
import '../../../../core/constants/report_enums.dart';

class ReportEntity extends Equatable {
  final int? id;
  final String? reporterId;
  final String targetId;
  final ReportTargetType targetType;
  final ReportCategory category;
  final String description;
  final ReportStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ReportEntity({
    this.id,
    this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.category,
    required this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        reporterId,
        targetId,
        targetType,
        category,
        description,
        status,
        createdAt,
        updatedAt,
      ];
}
