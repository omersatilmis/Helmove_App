import 'package:equatable/equatable.dart';

abstract class DiscoverEvent extends Equatable {
  const DiscoverEvent();

  @override
  List<Object> get props => [];
}

class SearchUsersEvent extends DiscoverEvent {
  final String query;
  final String? city;

  const SearchUsersEvent({required this.query, this.city});

  @override
  List<Object> get props => [query, city ?? ''];
}

class LoadDiscoveryContent extends DiscoverEvent {
  final bool isRefresh;
  const LoadDiscoveryContent({this.isRefresh = false});

  @override
  List<Object> get props => [isRefresh];
}

class ToggleDiscoverPostLikeEvent extends DiscoverEvent {
  final int postId;
  const ToggleDiscoverPostLikeEvent(this.postId);

  @override
  List<Object> get props => [postId];
}

class SyncDiscoverPostLikeStateEvent extends DiscoverEvent {
  final int postId;
  final bool isLiked;
  final int likeCount;

  const SyncDiscoverPostLikeStateEvent({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
  });

  @override
  List<Object> get props => [postId, isLiked, likeCount];
}

class LocalDeleteDiscoverPostEvent extends DiscoverEvent {
  final int postId;
  const LocalDeleteDiscoverPostEvent(this.postId);

  @override
  List<Object> get props => [postId];
}

class AdjustDiscoverPostCommentCountEvent extends DiscoverEvent {
  final int postId;
  final int delta;

  const AdjustDiscoverPostCommentCountEvent({
    required this.postId,
    required this.delta,
  });

  @override
  List<Object> get props => [postId, delta];
}
