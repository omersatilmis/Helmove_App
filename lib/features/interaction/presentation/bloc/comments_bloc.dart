import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/app_session.dart';
import '../../../auth/domain/usecases/get_current_user_id_use_case.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import 'comments_event.dart';
import 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  static const int _defaultPageSize = 10;

  final GetCommentsUseCase getComments;
  final AddCommentUseCase addComment;
  final DeleteCommentUseCase deleteComment;
  final GetCurrentUserIdUseCase getCurrentUserIdUseCase;
  final AppSession appSession;
  StreamSubscription<int?>? _appSessionUserIdSubscription;
  bool _isLoadingComments = false;

  CommentsBloc({
    required this.getComments,
    required this.addComment,
    required this.deleteComment,
    required this.getCurrentUserIdUseCase,
    required this.appSession,
  }) : super(const CommentsState()) {
    on<LoadCommentsEvent>(_onLoadComments);
    on<AddCommentEvent>(_onAddComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<CommentsCurrentUserChangedEvent>(_onCommentsCurrentUserChanged);

    Future.microtask(_initializeCurrentUserBridge);
  }

  Future<void> _initializeCurrentUserBridge() async {
    final userId = appSession.currentUserId ?? await getCurrentUserIdUseCase();
    if (!isClosed) {
      add(CommentsCurrentUserChangedEvent(userId));
    }

    _appSessionUserIdSubscription = appSession.currentUserIdStream.distinct().listen((userId) {
      if (!isClosed) {
        add(CommentsCurrentUserChangedEvent(userId));
      }
    });
  }

  void _onCommentsCurrentUserChanged(
    CommentsCurrentUserChangedEvent event,
    Emitter<CommentsState> emit,
  ) {
    if (state.currentUserId == event.userId) {
      return;
    }
    emit(state.copyWith(currentUserId: event.userId));
  }

  Future<void> _onLoadComments(
    LoadCommentsEvent event,
    Emitter<CommentsState> emit,
  ) async {
    // Has already reached max and not refreshing/first page
    if (state.hasReachedMax && !event.isRefresh && event.page > 1) return;
    if (_isLoadingComments) return;

    _isLoadingComments = true;

    try {
      if (event.isRefresh || event.page == 1) {
        emit(
          state.copyWith(
            status: CommentsStatus.loading,
            comments: [],
            hasReachedMax: false,
            currentPage: 1,
          ),
        );
      }

      final result = await getComments(
        GetCommentsParams(
          contentId: event.contentId,
          page: event.page,
          limit: event.limit,
        ),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: CommentsStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (comments) {
          final limit = event.limit > 0 ? event.limit : _defaultPageSize;
          if (event.page == 1) {
            emit(
              state.copyWith(
                status: CommentsStatus.success,
                comments: comments,
                hasReachedMax: comments.length < limit,
                currentPage: 1,
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: CommentsStatus.success,
                comments: List.of(state.comments)..addAll(comments),
                hasReachedMax: comments.length < limit,
                currentPage: event.page,
              ),
            );
          }
        },
      );
    } finally {
      _isLoadingComments = false;
    }
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
        emit(
          state.copyWith(
            isPostingComment: false,
            comments: updatedList,
            mutationRevision: state.mutationRevision + 1,
            lastMutationDelta: 1,
          ),
        );
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
      (_) {
        emit(
          state.copyWith(
            mutationRevision: state.mutationRevision + 1,
            lastMutationDelta: -1,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _appSessionUserIdSubscription?.cancel();
    return super.close();
  }
}
