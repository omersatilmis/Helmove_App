import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/accept_friend_request_usecase.dart';
import '../../../domain/usecases/block_user_usecase.dart';
import '../../../domain/usecases/reject_friend_request_usecase.dart';
import '../../../domain/usecases/remove_friend_usecase.dart';
import '../../../domain/usecases/send_friend_request_usecase.dart';
import '../../../domain/usecases/unblock_user_usecase.dart';
import 'friendship_action_event.dart';
import 'friendship_action_state.dart';

class FriendshipActionBloc
    extends Bloc<FriendshipActionEvent, FriendshipActionState> {
  final SendFriendRequestUseCase sendFriendRequest;
  final AcceptFriendRequestUseCase acceptFriendRequest;
  final RejectFriendRequestUseCase rejectFriendRequest;
  final RemoveFriendUseCase removeFriend;
  final BlockUserUseCase blockUser;
  final UnblockUserUseCase unblockUser;

  FriendshipActionBloc({
    required this.sendFriendRequest,
    required this.acceptFriendRequest,
    required this.rejectFriendRequest,
    required this.removeFriend,
    required this.blockUser,
    required this.unblockUser,
  }) : super(FriendshipActionInitial()) {
    on<SendFriendRequestEvent>(_onSendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptRequest);
    on<RejectFriendRequestEvent>(_onRejectRequest);
    on<RemoveFriendEvent>(_onRemoveFriend);
    on<BlockUserEvent>(_onBlockUser);
    on<UnblockUserEvent>(_onUnblockUser);
  }

  Future<void> _onSendRequest(
    SendFriendRequestEvent event,
    Emitter<FriendshipActionState> emit,
  ) async {
    emit(FriendshipActionLoading());
    final result = await sendFriendRequest(
      SendFriendRequestParams(
        targetUserId: event.targetUserId,
        message: event.message,
      ),
    );
    result.fold(
      (failure) => emit(FriendshipActionFailure(failure.message)),
      (success) =>
          emit(FriendshipActionSuccess("Friend request sent successfully")),
    );
  }

  Future<void> _onAcceptRequest(
    AcceptFriendRequestEvent event,
    Emitter<FriendshipActionState> emit,
  ) async {
    emit(FriendshipActionLoading());
    final result = await acceptFriendRequest(
      AcceptFriendRequestParams(friendshipId: event.friendshipId),
    );
    result.fold(
      (failure) => emit(FriendshipActionFailure(failure.message)),
      (success) => emit(FriendshipActionSuccess("Friend request accepted")),
    );
  }

  Future<void> _onRejectRequest(
    RejectFriendRequestEvent event,
    Emitter<FriendshipActionState> emit,
  ) async {
    emit(FriendshipActionLoading());
    final result = await rejectFriendRequest(
      RejectFriendRequestParams(friendshipId: event.friendshipId),
    );
    result.fold(
      (failure) => emit(FriendshipActionFailure(failure.message)),
      (success) => emit(FriendshipActionSuccess("Friend request rejected")),
    );
  }

  Future<void> _onRemoveFriend(
    RemoveFriendEvent event,
    Emitter<FriendshipActionState> emit,
  ) async {
    emit(FriendshipActionLoading());
    final result = await removeFriend(
      RemoveFriendParams(friendId: event.friendId),
    );
    result.fold(
      (failure) => emit(FriendshipActionFailure(failure.message)),
      (success) => emit(FriendshipActionSuccess("Friend removed")),
    );
  }

  Future<void> _onBlockUser(
    BlockUserEvent event,
    Emitter<FriendshipActionState> emit,
  ) async {
    emit(FriendshipActionLoading());
    final result = await blockUser(
      BlockUserParams(targetUserId: event.targetUserId),
    );
    result.fold(
      (failure) => emit(FriendshipActionFailure(failure.message)),
      (success) => emit(FriendshipActionSuccess("User blocked")),
    );
  }

  Future<void> _onUnblockUser(
    UnblockUserEvent event,
    Emitter<FriendshipActionState> emit,
  ) async {
    emit(FriendshipActionLoading());
    final result = await unblockUser(
      UnblockUserParams(targetUserId: event.targetUserId),
    );
    result.fold(
      (failure) => emit(FriendshipActionFailure(failure.message)),
      (success) => emit(FriendshipActionSuccess("User unblocked")),
    );
  }
}
