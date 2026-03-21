import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_followers_usecase.dart';
import '../../../domain/usecases/get_following_usecase.dart';
import 'follow_list_event.dart';
import 'follow_list_state.dart';

class FollowersListBloc extends Bloc<FollowListEvent, FollowListState> {
  final GetFollowersUseCase getFollowersUseCase;
  int _currentPage = 1;
  final int _pageSize = 20;

  FollowersListBloc({
    required this.getFollowersUseCase,
  }) : super(FollowListInitial()) {
    on<LoadFollowersEvent>(_onLoadFollowers);
    on<UpdateUserFollowStatusEvent>(_onUpdateUserFollowStatus);
  }

  void _onUpdateUserFollowStatus(
    UpdateUserFollowStatusEvent event,
    Emitter<FollowListState> emit,
  ) {
    if (state is FollowListLoaded) {
      final currentState = state as FollowListLoaded;
      final updatedUsers = currentState.users.map((user) {
        return user.id == event.userId
            ? user.copyWith(isFollowing: event.isFollowing)
            : user;
      }).toList();
      emit(currentState.copyWith(users: updatedUsers));
    }
  }

  Future<void> _onLoadFollowers(
    LoadFollowersEvent event,
    Emitter<FollowListState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = 1;
      emit(FollowListInitial());
    }

    if (state is FollowListLoaded && (state as FollowListLoaded).hasReachedMax) return;

    if (_currentPage == 1) {
      emit(FollowListLoading());
    }

    final result = await getFollowersUseCase(
      GetFollowersParams(userId: event.userId, page: _currentPage, pageSize: _pageSize),
    );

    result.fold(
      (failure) => emit(FollowListError(failure.message)),
      (users) {
        if (users.length < _pageSize) {
          emit(
            FollowListLoaded(
              users: _currentPage == 1 ? users : (state as FollowListLoaded).users + users,
              hasReachedMax: true,
            ),
          );
        } else {
          emit(
            FollowListLoaded(
              users: _currentPage == 1 ? users : (state as FollowListLoaded).users + users,
              hasReachedMax: false,
            ),
          );
          _currentPage++;
        }
      },
    );
  }
}

class FollowingListBloc extends Bloc<FollowListEvent, FollowListState> {
  final GetFollowingUseCase getFollowingUseCase;
  int _currentPage = 1;
  final int _pageSize = 20;

  FollowingListBloc({
    required this.getFollowingUseCase,
  }) : super(FollowListInitial()) {
    on<LoadFollowingEvent>(_onLoadFollowing);
    on<UpdateUserFollowStatusEvent>(_onUpdateUserFollowStatus);
  }

  void _onUpdateUserFollowStatus(
    UpdateUserFollowStatusEvent event,
    Emitter<FollowListState> emit,
  ) {
    if (state is FollowListLoaded) {
      final currentState = state as FollowListLoaded;
      final updatedUsers = currentState.users.map((user) {
        return user.id == event.userId
            ? user.copyWith(isFollowing: event.isFollowing)
            : user;
      }).toList();
      emit(currentState.copyWith(users: updatedUsers));
    }
  }

  Future<void> _onLoadFollowing(
    LoadFollowingEvent event,
    Emitter<FollowListState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = 1;
      emit(FollowListInitial());
    }

    if (state is FollowListLoaded && (state as FollowListLoaded).hasReachedMax) return;

    if (_currentPage == 1) {
      emit(FollowListLoading());
    }

    final result = await getFollowingUseCase(
      GetFollowingParams(userId: event.userId, page: _currentPage, pageSize: _pageSize),
    );

    result.fold(
      (failure) => emit(FollowListError(failure.message)),
      (users) {
        if (users.length < _pageSize) {
          emit(
            FollowListLoaded(
              users: _currentPage == 1 ? users : (state as FollowListLoaded).users + users,
              hasReachedMax: true,
            ),
          );
        } else {
          emit(
            FollowListLoaded(
              users: _currentPage == 1 ? users : (state as FollowListLoaded).users + users,
              hasReachedMax: false,
            ),
          );
          _currentPage++;
        }
      },
    );
  }
}
