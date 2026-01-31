import 'package:equatable/equatable.dart';
import '../../domain/entities/comment_entity.dart';

enum CommentsStatus { initial, loading, success, failure }

class CommentsState extends Equatable {
  final CommentsStatus status;
  final List<CommentEntity> comments;
  final String? errorMessage;
  final bool isPostingComment;

  const CommentsState({
    this.status = CommentsStatus.initial,
    this.comments = const [],
    this.errorMessage,
    this.isPostingComment = false,
  });

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentEntity>? comments,
    String? errorMessage,
    bool? isPostingComment,
  }) {
    return CommentsState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      errorMessage: errorMessage, // Nullable override
      isPostingComment: isPostingComment ?? this.isPostingComment,
    );
  }

  @override
  List<Object?> get props => [status, comments, errorMessage, isPostingComment];
}
