import 'package:equatable/equatable.dart';

enum CreatePostStatus { initial, submitting, success, failure }

class CreatePostState extends Equatable {
  final CreatePostStatus status;
  final String? errorMessage;

  const CreatePostState({
    this.status = CreatePostStatus.initial,
    this.errorMessage,
  });

  CreatePostState copyWith({CreatePostStatus? status, String? errorMessage}) {
    return CreatePostState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
