import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class TransferHostUseCase {
  final VoiceSessionRepository repository;

  TransferHostUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int sessionId, int newHostId) async {
    return await repository.transferHost(sessionId, newHostId);
  }
}
