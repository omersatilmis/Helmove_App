import '../../../../core/services/app_session.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserIdUseCase {
  final AppSession appSession;
  final AuthRepository authRepository;

  GetCurrentUserIdUseCase({
    required this.appSession,
    required this.authRepository,
  });

  Future<int?> call() async {
    final cachedUserId = appSession.currentUserId;
    if (cachedUserId != null) {
      return cachedUserId;
    }

    final persistedUser = await authRepository.getPersistedUser();
    if (persistedUser != null) {
      appSession.updateSession(
        currentUserId: persistedUser.id,
        currentUser: persistedUser,
        token: persistedUser.token,
      );
      return persistedUser.id;
    }

    return null;
  }
}
