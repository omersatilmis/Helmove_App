import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../../domain/entities/friendship_status.dart';
import '../../../domain/usecases/get_friendship_status_usecase.dart';
import '../../../domain/usecases/get_pending_requests_usecase.dart';
import '../../../domain/usecases/get_sent_requests_usecase.dart';
import 'friendship_status_event.dart';
import 'friendship_status_state.dart';

class FriendshipStatusBloc
    extends Bloc<FriendshipStatusEvent, FriendshipStatusState> {
  final GetFriendshipStatusUseCase getFriendshipStatus;
  final GetPendingRequestsUseCase getPendingRequests;
  final GetSentRequestsUseCase getSentRequests;

  FriendshipStatusBloc({
    required this.getFriendshipStatus,
    required this.getPendingRequests,
    required this.getSentRequests,
  }) : super(FriendshipStatusInitial()) {
    on<CheckFriendshipStatusEvent>(_onCheckStatus);
  }

  Future<void> _onCheckStatus(
    CheckFriendshipStatusEvent event,
    Emitter<FriendshipStatusState> emit,
  ) async {
    emit(FriendshipStatusLoading());

    final statusResult = await getFriendshipStatus(
      GetFriendshipStatusParams(targetUserId: event.targetUserId),
    );

    final status = statusResult.fold<FriendshipStatus?>(
      (failure) {
        emit(FriendshipStatusFailure(failure.message));
        return null;
      },
      (value) => value,
    );

    if (status == null) return;

    FriendRequestType requestType = FriendRequestType.none;
    int? friendshipId;

    if (status == FriendshipStatus.pending) {
      final pendingResult = await getPendingRequests(NoParams());
      pendingResult.fold(
        (_) {},
        (requests) {
          for (final request in requests) {
            if (request.requesterId == event.targetUserId) {
              requestType = FriendRequestType.received;
              friendshipId = request.id;
              return;
            }
          }
        },
      );

      if (friendshipId == null) {
        final sentResult = await getSentRequests(NoParams());
        sentResult.fold(
          (_) {},
          (requests) {
            for (final request in requests) {
              if (request.requesterId == event.targetUserId) {
                requestType = FriendRequestType.sent;
                friendshipId = request.id;
                return;
              }
            }
          },
        );
      }
    }

    emit(
      FriendshipStatusLoaded(
        status: status,
        requestType: requestType,
        friendshipId: friendshipId,
      ),
    );
  }
}
