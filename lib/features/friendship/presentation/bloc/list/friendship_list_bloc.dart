import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_friendship_stats_usecase.dart';
import '../../../domain/usecases/get_mutual_friends_usecase.dart';
import '../../../domain/usecases/get_my_friends_usecase.dart';
import '../../../domain/usecases/get_pending_requests_usecase.dart';
import '../../../domain/usecases/get_sent_requests_usecase.dart';
import '../../../domain/usecases/search_friends_usecase.dart';
import 'friendship_list_event.dart';
import 'friendship_list_state.dart';

class FriendshipListBloc
    extends Bloc<FriendshipListEvent, FriendshipListState> {
  final GetMyFriendsUseCase getMyFriends;
  final GetPendingRequestsUseCase getPendingRequests;
  final GetSentRequestsUseCase getSentRequests;
  final GetFriendshipStatsUseCase getStats;
  final GetMutualFriendsUseCase getMutualFriends;
  final SearchFriendsUseCase searchFriends;

  FriendshipListBloc({
    required this.getMyFriends,
    required this.getPendingRequests,
    required this.getSentRequests,
    required this.getStats,
    required this.getMutualFriends,
    required this.searchFriends,
  }) : super(FriendshipListInitial()) {
    on<LoadMyFriendsEvent>(_onLoadMyFriends);
    on<LoadPendingRequestsEvent>(_onLoadPendingRequests);
    on<LoadSentRequestsEvent>(_onLoadSentRequests);
    on<LoadFriendshipStatsEvent>(_onLoadStats);
    on<LoadMutualFriendsEvent>(_onLoadMutualFriends);
    on<SearchFriendsEvent>(_onSearchFriends);
  }

  Future<void> _onLoadMyFriends(
    LoadMyFriendsEvent event,
    Emitter<FriendshipListState> emit,
  ) async {
    emit(FriendshipListLoading());
    final result = await getMyFriends(NoParams());
    result.fold(
      (failure) => emit(FriendshipListFailure(failure.message)),
      (friends) => emit(MyFriendsLoaded(friends)),
    );
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingRequestsEvent event,
    Emitter<FriendshipListState> emit,
  ) async {
    emit(FriendshipListLoading());
    final result = await getPendingRequests(NoParams());
    result.fold(
      (failure) => emit(FriendshipListFailure(failure.message)),
      (requests) => emit(PendingRequestsLoaded(requests)),
    );
  }

  Future<void> _onLoadSentRequests(
    LoadSentRequestsEvent event,
    Emitter<FriendshipListState> emit,
  ) async {
    emit(FriendshipListLoading());
    final result = await getSentRequests(NoParams());
    result.fold(
      (failure) => emit(FriendshipListFailure(failure.message)),
      (requests) => emit(SentRequestsLoaded(requests)),
    );
  }

  Future<void> _onLoadStats(
    LoadFriendshipStatsEvent event,
    Emitter<FriendshipListState> emit,
  ) async {
    emit(FriendshipListLoading());
    final result = await getStats(
      GetFriendshipStatsParams(userId: event.userId),
    );
    result.fold(
      (failure) => emit(FriendshipListFailure(failure.message)),
      (stats) => emit(FriendshipStatsLoaded(stats)),
    );
  }

  Future<void> _onLoadMutualFriends(
    LoadMutualFriendsEvent event,
    Emitter<FriendshipListState> emit,
  ) async {
    emit(FriendshipListLoading());
    final result = await getMutualFriends(
      GetMutualFriendsParams(targetUserId: event.targetUserId),
    );
    result.fold(
      (failure) => emit(FriendshipListFailure(failure.message)),
      (mutuals) => emit(MutualFriendsLoaded(mutuals)),
    );
  }

  Future<void> _onSearchFriends(
    SearchFriendsEvent event,
    Emitter<FriendshipListState> emit,
  ) async {
    emit(FriendshipListLoading());
    final result = await searchFriends(SearchFriendsParams(query: event.query));
    result.fold(
      (failure) => emit(FriendshipListFailure(failure.message)),
      (results) => emit(FriendSearchResultsLoaded(results)),
    );
  }
}
