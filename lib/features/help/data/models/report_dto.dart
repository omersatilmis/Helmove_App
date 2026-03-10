import '../../../../core/constants/report_enums.dart';
import '../../domain/entities/report_entity.dart';

class ReportDto {
  final int? id;
  final String? reporterId;
  final String targetId;
  final int targetType;
  final int category;
  final String description;
  final int status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReportDto({
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

  factory ReportDto.fromJson(Map<String, dynamic> json) {
    return ReportDto(
      id: json['id'] as int?,
      reporterId: json['reporterId'] as String?,
      targetId: json['targetId'] as String,
      targetType: json['targetType'] as int,
      category: json['category'] as int,
      description: json['description'] as String,
      status: json['status'] as int,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (reporterId != null) 'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'category': category,
      'description': description,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  ReportEntity toEntity() {
    return ReportEntity(
      id: id,
      reporterId: reporterId,
      targetId: targetId,
      targetType: ReportTargetType.fromValue(targetType),
      category: ReportCategory.fromValue(category),
      description: description,
      status: ReportStatus.fromValue(status),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
