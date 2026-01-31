import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import 'comments_event.dart';
import 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final GetCommentsUseCase getComments;
  final AddCommentUseCase addComment;
  final DeleteCommentUseCase deleteComment;

  CommentsBloc({
    required this.getComments,
    required this.addComment,
    required this.deleteComment,
  }) : super(const CommentsState()) {
    on<LoadCommentsEvent>(_onLoadComments);
    on<AddCommentEvent>(_onAddComment);
    on<DeleteCommentEvent>(_onDeleteComment);
  }

  Future<void> _onLoadComments(
    LoadCommentsEvent event,
    Emitter<CommentsState> emit,
  ) async {
    if (event.isRefresh) {
      emit(state.copyWith(status: CommentsStatus.loading, comments: []));
    } else if (state.status == CommentsStatus.initial) {
      emit(state.copyWith(status: CommentsStatus.loading));
    }

    final result = await getComments(
      GetCommentsParams(contentId: event.contentId),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CommentsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (comments) => emit(
        state.copyWith(status: CommentsStatus.success, comments: comments),
      ),
    );
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<CommentsState> emit,
  ) async {
    emit(state.copyWith(isPostingComment: true));

    final result = await addComment(
      AddCommentParams(contentId: event.contentId, text: event.text),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isPostingComment: false,
          errorMessage: failure.message, // Maybe show snackbar separately
        ),
      ),
      (newComment) {
        final updatedList = List.of(state.comments)..add(newComment);
        emit(state.copyWith(isPostingComment: false, comments: updatedList));
      },
    );
  }

  Future<void> _onDeleteComment(
    DeleteCommentEvent event,
    Emitter<CommentsState> emit,
  ) async {
    // Optimistic delete
    final previousComments = List.of(state.comments);
    final updatedList = List.of(state.comments)
      ..removeWhere((c) => c.id == event.commentId);

    emit(state.copyWith(comments: updatedList));

    final result = await deleteComment(
      DeleteCommentParams(commentId: event.commentId),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            comments: previousComments,
            errorMessage: failure.message,
          ),
        );
      },
      (_) {}, // Success
    );
  }
}
