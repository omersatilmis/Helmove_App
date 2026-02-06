import '../entities/call_entities.dart';
import '../repositories/call_repository.dart';

class SendCallRequestUseCase {
  final CallRepository repository;
  SendCallRequestUseCase(this.repository);

  Future<CallResponseEntity> execute(CallRequestEntity request) async {
    return await repository.sendCallRequest(request);
  }
}

class AcceptCallUseCase {
  final CallRepository repository;
  AcceptCallUseCase(this.repository);

  Future<void> execute(int callId) async {
    return await repository.acceptCall(callId);
  }
}

class RejectCallUseCase {
  final CallRepository repository;
  RejectCallUseCase(this.repository);

  Future<void> execute(int callId) async {
    return await repository.rejectCall(callId);
  }
}

class EndCallUseCase {
  final CallRepository repository;
  EndCallUseCase(this.repository);

  Future<void> execute(int callId) async {
    return await repository.endCall(callId);
  }
}

class GetOnlineUsersUseCase {
  final CallRepository repository;
  GetOnlineUsersUseCase(this.repository);

  Future<OnlineUsersEntity> execute() async {
    return await repository.getOnlineUsers();
  }
}

class CheckUserOnlineStatusUseCase {
  final CallRepository repository;
  CheckUserOnlineStatusUseCase(this.repository);

  Future<bool> execute(String userId) async {
    return await repository.isUserOnline(userId);
  }
}

class GetPendingCallsUseCase {
  final CallRepository repository;
  GetPendingCallsUseCase(this.repository);

  Future<List<CallResponseEntity>> execute() async {
    return await repository.getPendingCalls();
  }
}
