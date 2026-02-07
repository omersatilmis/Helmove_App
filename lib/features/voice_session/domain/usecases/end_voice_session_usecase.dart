import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class EndVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  EndVoiceSessionUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int id) async {
    return await repository.endSession(id);
  }
}
