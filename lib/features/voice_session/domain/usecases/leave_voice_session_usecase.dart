import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class LeaveVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  LeaveVoiceSessionUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int id) async {
    return await repository.leaveSession(id);
  }
}
