import 'package:equatable/equatable.dart';
import '../../domain/entities/comment_entity.dart';

enum CommentsStatus { initial, loading, success, failure }

class CommentsState extends Equatable {
  final CommentsStatus status;
  final List<CommentEntity> comments;
  final String? errorMessage;
  final bool isPostingComment;
  final bool hasReachedMax;
  final int currentPage;

  const CommentsState({
    this.status = CommentsStatus.initial,
    this.comments = const [],
    this.errorMessage,
    this.isPostingComment = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
  });

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentEntity>? comments,
    String? errorMessage,
    bool? isPostingComment,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return CommentsState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      errorMessage: errorMessage,
      isPostingComment: isPostingComment ?? this.isPostingComment,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    comments,
    errorMessage,
    isPostingComment,
    hasReachedMax,
    currentPage,
  ];
}
