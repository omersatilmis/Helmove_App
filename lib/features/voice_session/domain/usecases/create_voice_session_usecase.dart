import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/dto/create_voice_session_request_dto.dart';
import '../repositories/voice_session_repository.dart';

class CreateVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  CreateVoiceSessionUseCase(this.repository);

  Future<Either<Failure, int>> call(
    CreateVoiceSessionRequestDto request,
  ) async {
    return await repository.createSession(request);
  }
}
