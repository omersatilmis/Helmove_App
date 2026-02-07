import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/voice_session_entity.dart';
import '../repositories/voice_session_repository.dart';

class GetMyVoiceSessionsUseCase {
  final VoiceSessionRepository repository;

  GetMyVoiceSessionsUseCase(this.repository);

  Future<Either<Failure, List<VoiceSessionEntity>>> call() async {
    return await repository.getMySessions();
  }
}
