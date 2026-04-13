import 'package:equatable/equatable.dart';
import '../../domain/entities/comment_entity.dart';

enum CommentsStatus { initial, loading, success, failure }

class CommentsState extends Equatable {
  final CommentsStatus status;
  final List<CommentEntity> comments;
  final int? currentUserId;
  final String? errorMessage;
  final bool isPostingComment;
  final bool hasReachedMax;
  final int currentPage;
  final int mutationRevision;
  final int lastMutationDelta;

  const CommentsState({
    this.status = CommentsStatus.initial,
    this.comments = const [],
    this.currentUserId,
    this.errorMessage,
    this.isPostingComment = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.mutationRevision = 0,
    this.lastMutationDelta = 0,
  });

  CommentsState copyWith({
    CommentsStatus? status,
    List<CommentEntity>? comments,
    int? currentUserId,
    String? errorMessage,
    bool? isPostingComment,
    bool? hasReachedMax,
    int? currentPage,
    int? mutationRevision,
    int? lastMutationDelta,
  }) {
    return CommentsState(
      status: status ?? this.status,
      comments: comments ?? this.comments,
      currentUserId: currentUserId ?? this.currentUserId,
      errorMessage: errorMessage,
      isPostingComment: isPostingComment ?? this.isPostingComment,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      mutationRevision: mutationRevision ?? this.mutationRevision,
      lastMutationDelta: lastMutationDelta ?? this.lastMutationDelta,
    );
  }

  @override
  List<Object?> get props => [
    status,
    comments,
    currentUserId,
    errorMessage,
    isPostingComment,
    hasReachedMax,
    currentPage,
    mutationRevision,
    lastMutationDelta,
  ];
}
