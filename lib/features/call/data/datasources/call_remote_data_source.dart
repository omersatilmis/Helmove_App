import '../api/call_api.dart';
import '../models/call_models.dart';

abstract class CallRemoteDataSource {
  Future<CallResponseModel> sendCallRequest(CallRequestModel request);
  Future<void> acceptCall(int callId);
  Future<void> rejectCall(int callId);
  Future<void> endCall(int callId);
  Future<OnlineUsersModel> getOnlineUsers();
  Future<bool> isUserOnline(String userId);
  Future<List<CallResponseModel>> getPendingCalls();
}

class CallRemoteDataSourceImpl implements CallRemoteDataSource {
  final CallApi api;

  CallRemoteDataSourceImpl(this.api);

  @override
  Future<CallResponseModel> sendCallRequest(CallRequestModel request) async {
    return await api.sendCallRequest(request);
  }

  @override
  Future<void> acceptCall(int callId) async {
    return await api.acceptCall(callId);
  }

  @override
  Future<void> rejectCall(int callId) async {
    return await api.rejectCall(callId);
  }

  @override
  Future<void> endCall(int callId) async {
    return await api.endCall(callId);
  }

  @override
  Future<OnlineUsersModel> getOnlineUsers() async {
    return await api.getOnlineUsers();
  }

  @override
  Future<bool> isUserOnline(String userId) async {
    return await api.isUserOnline(userId);
  }

  @override
  Future<List<CallResponseModel>> getPendingCalls() async {
    return await api.getPendingCalls();
  }
}
