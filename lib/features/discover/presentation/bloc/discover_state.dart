import 'package:equatable/equatable.dart';
import '../../../friendship/domain/entities/friend_user_entity.dart';
import '../../../content/posts/domain/entities/post_entity.dart';

abstract class DiscoverState extends Equatable {
  const DiscoverState();

  @override
  List<Object> get props => [];
}

class DiscoverInitial extends DiscoverState {}

class DiscoverLoading extends DiscoverState {}

class DiscoverLoaded extends DiscoverState {
  final List<FriendUserEntity> results;

  const DiscoverLoaded(this.results);

  @override
  List<Object> get props => [results];
}

class DiscoverDiscoveryLoaded extends DiscoverState {
  final List<PostEntity> content;
  final int page;
  final bool hasReachedMax;

  const DiscoverDiscoveryLoaded({
    required this.content,
    this.page = 1,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [content, page, hasReachedMax];
}

class DiscoverFailure extends DiscoverState {
  final String message;

  const DiscoverFailure(this.message);

  @override
  List<Object> get props => [message];
}
