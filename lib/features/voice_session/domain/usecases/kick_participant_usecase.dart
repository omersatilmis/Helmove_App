import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/voice_session_repository.dart';

class KickParticipantUseCase {
  final VoiceSessionRepository repository;

  KickParticipantUseCase(this.repository);

  Future<Either<Failure, Unit>> call(int rideId, int targetUserId) async {
    return await repository.kickParticipant(rideId, targetUserId);
  }
}
