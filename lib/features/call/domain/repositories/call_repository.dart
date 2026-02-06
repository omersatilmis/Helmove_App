import '../entities/call_entities.dart';

abstract class CallRepository {
  Future<CallResponseEntity> sendCallRequest(CallRequestEntity request);
  Future<void> acceptCall(int callId);
  Future<void> rejectCall(int callId);
  Future<void> endCall(int callId);
  Future<OnlineUsersEntity> getOnlineUsers();
  Future<bool> isUserOnline(String userId);
  Future<List<CallResponseEntity>> getPendingCalls();
}
