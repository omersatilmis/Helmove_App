import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/dto/invite_users_request_dto.dart';
import '../repositories/voice_session_repository.dart';

class InviteToVoiceSessionUseCase {
  final VoiceSessionRepository repository;

  InviteToVoiceSessionUseCase(this.repository);

  Future<Either<Failure, Unit>> call(
    int id,
    InviteUsersRequestDto request,
  ) async {
    return await repository.inviteUsers(id, request);
  }
}
