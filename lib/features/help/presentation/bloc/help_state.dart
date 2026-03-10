import 'package:equatable/equatable.dart';

enum HelpStatus { initial, loading, success, failure }

class HelpState extends Equatable {
  final HelpStatus status;
  final String? errorMessage;
  final String? successMessage;

  const HelpState({
    this.status = HelpStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  HelpState copyWith({
    HelpStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return HelpState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage];
}
