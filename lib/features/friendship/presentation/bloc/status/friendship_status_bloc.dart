import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_friendship_status_usecase.dart';
import 'friendship_status_event.dart';
import 'friendship_status_state.dart';

class FriendshipStatusBloc
    extends Bloc<FriendshipStatusEvent, FriendshipStatusState> {
  final GetFriendshipStatusUseCase getFriendshipStatus;

  FriendshipStatusBloc({required this.getFriendshipStatus})
    : super(FriendshipStatusInitial()) {
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

    statusResult.fold(
      (failure) => emit(FriendshipStatusFailure(failure.message)),
      (status) {
        // We simplified this to NOT fetch lists.
        // requestType will be none, and friendshipId will be null.
        // The ProfileInfo UI will handle status correctly based on FriendshipStatus enum.
        emit(
          FriendshipStatusLoaded(
            status: status,
            requestType: FriendRequestType.none,
            friendshipId: null,
          ),
        );
      },
    );
  }
}
