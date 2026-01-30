import 'package:equatable/equatable.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

class GetFeedEvent extends PostsEvent {
  final int page;
  final bool isRefresh;

  const GetFeedEvent({this.page = 1, this.isRefresh = false});

  @override
  List<Object?> get props => [page, isRefresh];
}

class GetUserPostsEvent extends PostsEvent {
  final int userId;
  final int page;
  final bool isRefresh;

  const GetUserPostsEvent({
    required this.userId,
    this.page = 1,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [userId, page, isRefresh];
}

class DeletePostEvent extends PostsEvent {
  final int postId;

  const DeletePostEvent(this.postId);

  @override
  List<Object?> get props => [postId];
}
