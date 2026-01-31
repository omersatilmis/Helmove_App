import 'package:equatable/equatable.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object> get props => [];
}

class LoadCommentsEvent extends CommentsEvent {
  final int contentId;
  final bool isRefresh;

  const LoadCommentsEvent({required this.contentId, this.isRefresh = false});

  @override
  List<Object> get props => [contentId, isRefresh];
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
