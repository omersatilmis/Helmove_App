import '../../domain/entities/call_entities.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/call_remote_data_source.dart';
import '../models/call_models.dart';

class CallRepositoryImpl implements CallRepository {
  final CallRemoteDataSource remoteDataSource;

  CallRepositoryImpl(this.remoteDataSource);

  @override
  Future<CallResponseEntity> sendCallRequest(CallRequestEntity request) async {
    final model = CallRequestModel(
      targetUserId: request.targetUserId,
      callType: request.callType,
      notes: request.notes,
    );
    return await remoteDataSource.sendCallRequest(model);
  }

  @override
  Future<void> acceptCall(int callId) async {
    return await remoteDataSource.acceptCall(callId);
  }

  @override
  Future<void> rejectCall(int callId) async {
    return await remoteDataSource.rejectCall(callId);
  }

  @override
  Future<void> endCall(int callId) async {
    return await remoteDataSource.endCall(callId);
  }

  @override
  Future<OnlineUsersEntity> getOnlineUsers() async {
    return await remoteDataSource.getOnlineUsers();
  }

  @override
  Future<bool> isUserOnline(String userId) async {
    return await remoteDataSource.isUserOnline(userId);
  }

  @override
  Future<List<CallResponseEntity>> getPendingCalls() async {
    return await remoteDataSource.getPendingCalls();
  }
}
