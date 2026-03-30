import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/follow_user.dart';
import '../../../domain/usecases/get_followers_usecase.dart';
import '../../../domain/usecases/get_following_usecase.dart';
import '../../../domain/usecases/get_blocked_users_usecase.dart';
import '../../../../../core/usecases/usecase.dart';
import 'follow_list_event.dart';
import 'follow_list_state.dart';

class FollowersListBloc extends Bloc<FollowListEvent, FollowListState> {
  final GetFollowersUseCase getFollowersUseCase;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;

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
    if (_isLoading) {
      return;
    }

    if (event.refresh) {
      _currentPage = 1;
    }

    final currentState = state;
    final List<FollowUser> previousUsers =
        currentState is FollowListLoaded && !event.refresh
            ? currentState.users
            : const [];

    if (!event.refresh &&
        currentState is FollowListLoaded &&
        currentState.hasReachedMax) {
      return;
    }

    if (_currentPage == 1 && previousUsers.isEmpty) {
      emit(FollowListLoading());
    }

    _isLoading = true;
    final result = await getFollowersUseCase(
      GetFollowersParams(
        userId: event.userId,
        page: _currentPage,
        pageSize: _pageSize,
      ),
    ).whenComplete(() => _isLoading = false);

    result.fold(
      (failure) => emit(FollowListError(failure.message)),
      (users) {
        final List<FollowUser> mergedUsers =
            _currentPage == 1 ? users : _mergeUsers(previousUsers, users);
        final bool hasReachedMax = users.length < _pageSize;

        if (users.length < _pageSize) {
          emit(
            FollowListLoaded(
              users: mergedUsers,
              hasReachedMax: true,
            ),
          );
        } else {
          emit(
            FollowListLoaded(
              users: mergedUsers,
              hasReachedMax: hasReachedMax,
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
  bool _isLoading = false;

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
    if (_isLoading) {
      return;
    }

    if (event.refresh) {
      _currentPage = 1;
    }

    final currentState = state;
    final List<FollowUser> previousUsers =
        currentState is FollowListLoaded && !event.refresh
            ? currentState.users
            : const [];

    if (!event.refresh &&
        currentState is FollowListLoaded &&
        currentState.hasReachedMax) {
      return;
    }

    if (_currentPage == 1 && previousUsers.isEmpty) {
      emit(FollowListLoading());
    }

    _isLoading = true;
    final result = await getFollowingUseCase(
      GetFollowingParams(
        userId: event.userId,
        page: _currentPage,
        pageSize: _pageSize,
      ),
    ).whenComplete(() => _isLoading = false);

    result.fold(
      (failure) => emit(FollowListError(failure.message)),
      (users) {
        final List<FollowUser> mergedUsers =
            _currentPage == 1 ? users : _mergeUsers(previousUsers, users);
        final bool hasReachedMax = users.length < _pageSize;

        if (users.length < _pageSize) {
          emit(
            FollowListLoaded(
              users: mergedUsers,
              hasReachedMax: true,
            ),
          );
        } else {
          emit(
            FollowListLoaded(
              users: mergedUsers,
              hasReachedMax: hasReachedMax,
            ),
          );
          _currentPage++;
        }
      },
    );
  }
}

class BlockedListBloc extends Bloc<FollowListEvent, FollowListState> {
  final GetBlockedUsersUseCase getBlockedUsersUseCase;
  bool _isLoading = false;

  BlockedListBloc({
    required this.getBlockedUsersUseCase,
  }) : super(FollowListInitial()) {
    on<LoadBlockedUsersEvent>(_onLoadBlockedUsers);
  }

  Future<void> _onLoadBlockedUsers(
    LoadBlockedUsersEvent event,
    Emitter<FollowListState> emit,
  ) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    emit(FollowListLoading());

    final result = await getBlockedUsersUseCase(
      NoParams(),
    ).whenComplete(() => _isLoading = false);

    result.fold(
      (failure) => emit(FollowListError(failure.message)),
      (users) {
        emit(
          FollowListLoaded(
            users: users,
            hasReachedMax: true,
          ),
        );
      },
    );
  }
}

List<FollowUser> _mergeUsers(List<FollowUser> previous, List<FollowUser> incoming) {
  final merged = <int, FollowUser>{};
  for (final user in previous) {
    merged[user.id] = user;
  }
  for (final user in incoming) {
    merged[user.id] = user;
  }
  return merged.values.toList(growable: false);
}
