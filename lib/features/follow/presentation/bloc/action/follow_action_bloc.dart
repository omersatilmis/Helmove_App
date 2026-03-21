import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/follow_block_user_usecase.dart';
import '../../../domain/usecases/follow_user_usecase.dart';
import '../../../domain/usecases/follow_unblock_user_usecase.dart';
import '../../../domain/usecases/unfollow_user_usecase.dart';
import 'follow_action_event.dart';
import 'follow_action_state.dart';

class FollowActionBloc extends Bloc<FollowActionEvent, FollowActionState> {
  final FollowUserUseCase followUserUseCase;
  final UnfollowUserUseCase unfollowUserUseCase;
  final FollowBlockUserUseCase blockUserUseCase;
  final FollowUnblockUserUseCase unblockUserUseCase;

  FollowActionBloc({
    required this.followUserUseCase,
    required this.unfollowUserUseCase,
    required this.blockUserUseCase,
    required this.unblockUserUseCase,
  }) : super(FollowActionInitial()) {
    on<FollowUserEvent>(_onFollowUser);
    on<UnfollowUserEvent>(_onUnfollowUser);
    on<BlockUserEvent>(_onBlockUser);
    on<UnblockUserEvent>(_onUnblockUser);
  }

  Future<void> _onFollowUser(
    FollowUserEvent event,
    Emitter<FollowActionState> emit,
  ) async {
    emit(FollowActionLoading(event.userId));
    final result = await followUserUseCase(event.userId);
    result.fold(
      (failure) => emit(FollowActionError(failure.message)),
      (_) => emit(FollowUserSuccess(event.userId)),
    );
  }

  Future<void> _onUnfollowUser(
    UnfollowUserEvent event,
    Emitter<FollowActionState> emit,
  ) async {
    emit(FollowActionLoading(event.userId));
    final result = await unfollowUserUseCase(event.userId);
    result.fold(
      (failure) => emit(FollowActionError(failure.message)),
      (_) => emit(UnfollowUserSuccess(event.userId)),
    );
  }

  Future<void> _onBlockUser(
    BlockUserEvent event,
    Emitter<FollowActionState> emit,
  ) async {
    emit(FollowActionLoading(event.userId));
    final result = await blockUserUseCase(event.userId);
    result.fold(
      (failure) => emit(FollowActionError(failure.message)),
      (_) => emit(BlockUserSuccess(event.userId)),
    );
  }

  Future<void> _onUnblockUser(
    UnblockUserEvent event,
    Emitter<FollowActionState> emit,
  ) async {
    emit(FollowActionLoading(event.userId));
    final result = await unblockUserUseCase(event.userId);
    result.fold(
      (failure) => emit(FollowActionError(failure.message)),
      (_) => emit(UnblockUserSuccess(event.userId)),
    );
  }
}
