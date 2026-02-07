import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/voice_session_entity.dart';
import '../repositories/voice_session_repository.dart';

class GetVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  GetVoiceSessionUseCase(this.repository);

  Future<Either<Failure, VoiceSessionEntity>> call(int id) async {
    return await repository.getSession(id);
  }
}
