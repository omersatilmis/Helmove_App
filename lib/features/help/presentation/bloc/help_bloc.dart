import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_report_usecase.dart';
import '../../domain/usecases/send_feedback_usecase.dart';
import 'help_event.dart';
import 'help_state.dart';

class HelpBloc extends Bloc<HelpEvent, HelpState> {
  final CreateReportUseCase createReportUseCase;
  final SendFeedbackUseCase sendFeedbackUseCase;

  HelpBloc({
    required this.createReportUseCase,
    required this.sendFeedbackUseCase,
  }) : super(const HelpState()) {
    on<CreateReportEvent>(_onCreateReport);
    on<SendFeedbackEvent>(_onSendFeedback);
    on<ResetHelpStatusEvent>(_onResetStatus);
  }

  Future<void> _onCreateReport(
    CreateReportEvent event,
    Emitter<HelpState> emit,
  ) async {
    emit(state.copyWith(status: HelpStatus.loading));

    final result = await createReportUseCase(event.report);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HelpStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: HelpStatus.success,
        successMessage: 'Raporunuz başarıyla iletildi. Teşekkür ederiz.',
      )),
    );
  }

  Future<void> _onSendFeedback(
    SendFeedbackEvent event,
    Emitter<HelpState> emit,
  ) async {
    emit(state.copyWith(status: HelpStatus.loading));

    final result = await sendFeedbackUseCase(event.feedback);

    result.fold(
      (failure) => emit(state.copyWith(
        status: HelpStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: HelpStatus.success,
        successMessage: 'Geri bildiriminiz alındı. Katkınız için teşekkürler!',
      )),
    );
  }

  void _onResetStatus(
    ResetHelpStatusEvent event,
    Emitter<HelpState> emit,
  ) {
    emit(const HelpState());
  }
}
