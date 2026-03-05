import 'package:equatable/equatable.dart';
import '../../domain/entities/post_entity.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

class GetFeedEvent extends PostsEvent {
  final int page;
  final int limit;
  final bool isRefresh;

  const GetFeedEvent({this.page = 1, this.limit = 10, this.isRefresh = false});

  @override
  List<Object?> get props => [page, limit, isRefresh];
}

class GetUserPostsEvent extends PostsEvent {
  final int userId;
  final int page;
  final int limit;
  final bool isRefresh;

  const GetUserPostsEvent({
    required this.userId,
    this.page = 1,
    this.limit = 10,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [userId, page, limit, isRefresh];
}

class DeletePostEvent extends PostsEvent {
  final int postId;

  const DeletePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

class LikePostEvent extends PostsEvent {
  final int postId;

  const LikePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}

class PostsCurrentUserChangedEvent extends PostsEvent {
  final int? userId;

  const PostsCurrentUserChangedEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SeedInitialFeedEvent extends PostsEvent {
  final List<PostEntity> posts;
  final bool hasNextPage;
  final int page;

  const SeedInitialFeedEvent({
    required this.posts,
    required this.hasNextPage,
    this.page = 1,
  });

  @override
  List<Object?> get props => [posts, hasNextPage, page];
}
