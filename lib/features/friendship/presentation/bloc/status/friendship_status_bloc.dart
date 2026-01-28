import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/entities/friendship_status.dart';
import '../../../domain/usecases/get_friendship_status_usecase.dart';
import '../../../domain/usecases/get_sent_requests_usecase.dart';
import '../../../domain/usecases/get_pending_requests_usecase.dart';
import 'friendship_status_event.dart';
import 'friendship_status_state.dart';

import '../../../domain/usecases/get_my_friends_usecase.dart';

class FriendshipStatusBloc
    extends Bloc<FriendshipStatusEvent, FriendshipStatusState> {
  final GetFriendshipStatusUseCase getFriendshipStatus;
  final GetSentRequestsUseCase getSentRequests;
  final GetPendingRequestsUseCase getPendingRequests;
  final GetMyFriendsUseCase getMyFriends;

  FriendshipStatusBloc({
    required this.getFriendshipStatus,
    required this.getSentRequests,
    required this.getPendingRequests,
    required this.getMyFriends,
  }) : super(FriendshipStatusInitial()) {
    on<CheckFriendshipStatusEvent>(_onCheckStatus);
  }

  Future<void> _onCheckStatus(
    CheckFriendshipStatusEvent event,
    Emitter<FriendshipStatusState> emit,
  ) async {
    // Avoid double loading if possible, but for now simple state machine
    emit(FriendshipStatusLoading());

    // 1. Get Status
    final statusResult = await getFriendshipStatus(
      GetFriendshipStatusParams(targetUserId: event.targetUserId),
    );

    await statusResult.fold(
      (failure) async => emit(FriendshipStatusFailure(failure.message)),
      (status) async {
        FriendRequestType requestType = FriendRequestType.none;
        int? foundFriendshipId;

        if (status == FriendshipStatus.pending) {
          // ... (Logic for pending - keep as is)
          final pendingResult = await getPendingRequests(NoParams());

          bool isReceived = false;
          pendingResult.fold((l) {}, (list) {
            try {
              final req = list.firstWhere(
                (req) => req.requesterId == event.targetUserId,
              );
              isReceived = true;
              foundFriendshipId = req.id;
            } catch (_) {
              isReceived = false;
            }
          });

          if (isReceived) {
            requestType = FriendRequestType.received;
          } else {
            requestType = FriendRequestType.sent;
          }
        } else if (status == FriendshipStatus.accepted) {
          // Fetch my friends to find the friendshipId (id in FriendUserModel)
          final friendsResult = await getMyFriends(NoParams());
          friendsResult.fold((l) {}, (list) {
            try {
              final friend = list.firstWhere(
                (f) => f.userId == event.targetUserId,
              );
              foundFriendshipId = friend.id;
            } catch (_) {
              // Not found in friends list (sync issue?)
            }
          });
        }

        emit(
          FriendshipStatusLoaded(
            status: status,
            requestType: requestType,
            friendshipId: foundFriendshipId,
          ),
        );
      },
    );
  }
}
