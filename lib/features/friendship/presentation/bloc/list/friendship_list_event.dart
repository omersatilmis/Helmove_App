import 'package:equatable/equatable.dart';

abstract class FriendshipListEvent extends Equatable {
  const FriendshipListEvent();

  @override
  List<Object> get props => [];
}

class LoadMyFriendsEvent extends FriendshipListEvent {}

class LoadPendingRequestsEvent extends FriendshipListEvent {}

class LoadSentRequestsEvent extends FriendshipListEvent {}

class LoadFriendshipStatsEvent extends FriendshipListEvent {}

class LoadMutualFriendsEvent extends FriendshipListEvent {
  final int targetUserId;

  const LoadMutualFriendsEvent({required this.targetUserId});

  @override
  List<Object> get props => [targetUserId];
}

class SearchFriendsEvent extends FriendshipListEvent {
  final String query;

  const SearchFriendsEvent({required this.query});

  @override
  List<Object> get props => [query];
}
