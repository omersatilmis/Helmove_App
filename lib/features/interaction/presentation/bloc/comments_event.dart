import 'package:equatable/equatable.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object> get props => [];
}

class LoadCommentsEvent extends CommentsEvent {
  final int contentId;
  final bool isRefresh;
  final int page;
  final int limit;

  const LoadCommentsEvent({
    required this.contentId,
    this.isRefresh = false,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object> get props => [contentId, isRefresh, page, limit];
}

class AddCommentEvent extends CommentsEvent {
  final int contentId;
  final String text;

  const AddCommentEvent({required this.contentId, required this.text});

  @override
  List<Object> get props => [contentId, text];
}

class DeleteCommentEvent extends CommentsEvent {
  final int commentId;
  final int contentId; // To reload or update list

  const DeleteCommentEvent({required this.commentId, required this.contentId});

  @override
  List<Object> get props => [commentId, contentId];
}

class CommentsCurrentUserChangedEvent extends CommentsEvent {
  final int? userId;

  const CommentsCurrentUserChangedEvent(this.userId);

  @override
  List<Object> get props => userId == null ? const [] : [userId!];
}
