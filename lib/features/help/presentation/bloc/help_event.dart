import 'package:equatable/equatable.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/feedback_entity.dart';

abstract class HelpEvent extends Equatable {
  const HelpEvent();

  @override
  List<Object?> get props => [];
}

class CreateReportEvent extends HelpEvent {
  final ReportEntity report;
  const CreateReportEvent(this.report);

  @override
  List<Object?> get props => [report];
}

class SendFeedbackEvent extends HelpEvent {
  final FeedbackEntity feedback;
  const SendFeedbackEvent(this.feedback);

  @override
  List<Object?> get props => [feedback];
}

class ResetHelpStatusEvent extends HelpEvent {}
