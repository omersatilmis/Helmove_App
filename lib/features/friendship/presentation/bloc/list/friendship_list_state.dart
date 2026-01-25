import 'package:equatable/equatable.dart';
import '../../../domain/entities/friend_request_entity.dart';
import '../../../domain/entities/friend_stats_entity.dart';
import '../../../domain/entities/friend_user_entity.dart';

abstract class FriendshipListState extends Equatable {
  const FriendshipListState();

  @override
  List<Object> get props => [];
}

class FriendshipListInitial extends FriendshipListState {}

class FriendshipListLoading extends FriendshipListState {}

class MyFriendsLoaded extends FriendshipListState {
  final List<FriendUserEntity> friends;

  const MyFriendsLoaded(this.friends);

  @override
  List<Object> get props => [friends];
}

class PendingRequestsLoaded extends FriendshipListState {
  final List<FriendRequestEntity> requests;

  const PendingRequestsLoaded(this.requests);

  @override
  List<Object> get props => [requests];
}

class SentRequestsLoaded extends FriendshipListState {
  final List<FriendRequestEntity> requests;

  const SentRequestsLoaded(this.requests);

  @override
  List<Object> get props => [requests];
}

class FriendshipStatsLoaded extends FriendshipListState {
  final FriendStatsEntity stats;

  const FriendshipStatsLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

class MutualFriendsLoaded extends FriendshipListState {
  final List<FriendUserEntity> mutualFriends;

  const MutualFriendsLoaded(this.mutualFriends);

  @override
  List<Object> get props => [mutualFriends];
}

class FriendSearchResultsLoaded extends FriendshipListState {
  final List<FriendUserEntity> results;

  const FriendSearchResultsLoaded(this.results);

  @override
  List<Object> get props => [results];
}

class FriendshipListFailure extends FriendshipListState {
  final String message;

  const FriendshipListFailure(this.message);

  @override
  List<Object> get props => [message];
}
