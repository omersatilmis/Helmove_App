import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/app_session.dart';
import '../../../../auth/domain/usecases/get_current_user_id_use_case.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import '../../domain/usecases/get_user_posts_usecase.dart';
import '../../domain/usecases/like_post_usecase.dart';
import '../../domain/entities/post_entity.dart';
import 'posts_event.dart';
import 'posts_state.dart';

import '../../../../../core/models/paged_result.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPostsFeedUseCase getFeed;
  final GetUserPostsUseCase getUserPosts;
  final DeletePostUseCase deletePost;
  final LikePostUseCase likePost;
  final GetCurrentUserIdUseCase getCurrentUserIdUseCase;
  final AppSession appSession;
  StreamSubscription<int?>? _appSessionUserIdSubscription;

  PostsBloc({
    required this.getFeed,
    required this.getUserPosts,
    required this.deletePost,
    required this.likePost,
    required this.getCurrentUserIdUseCase,
    required this.appSession,
  }) : super(const PostsState()) {
    on<GetFeedEvent>(_onGetFeed);
    on<GetUserPostsEvent>(_onGetUserPosts);
    on<DeletePostEvent>(_onDeletePost);
    on<LikePostEvent>(_onLikePost);
    on<PostsCurrentUserChangedEvent>(_onPostsCurrentUserChanged);

    Future.microtask(_initializeCurrentUserBridge);
  }

  Future<void> _initializeCurrentUserBridge() async {
    final userId = appSession.currentUserId ?? await getCurrentUserIdUseCase();
    if (!isClosed) {
      add(PostsCurrentUserChangedEvent(userId));
    }

    _appSessionUserIdSubscription = appSession.currentUserIdStream.distinct().listen((userId) {
      if (!isClosed) {
        add(PostsCurrentUserChangedEvent(userId));
      }
    });
  }

  void _onPostsCurrentUserChanged(
    PostsCurrentUserChangedEvent event,
    Emitter<PostsState> emit,
  ) {
    if (state.currentUserId == event.userId) {
      return;
    }
    emit(state.copyWith(currentUserId: event.userId));
  }

  Future<void> _onGetFeed(GetFeedEvent event, Emitter<PostsState> emit) async {
    try {
      // Prevent duplicate requests if already loading or reached max/has no more pages
      if (state.status == PostsStatus.loading) return;
      if (state.hasReachedMax && !event.isRefresh && event.page != 1) return;

      emit(
        state.copyWith(
          status: PostsStatus.loading,
          posts: event.isRefresh ? [] : state.posts,
        ),
      );

      final result = await getFeed(
        GetFeedParams(page: event.page, limit: event.limit),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: PostsStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (PagedResult<PostEntity> pagedResult) {
          final List<PostEntity> allPosts = event.isRefresh
              ? []
              : List<PostEntity>.from(state.posts);

          allPosts.addAll(pagedResult.items);

          emit(
            state.copyWith(
              status: PostsStatus.success,
              posts: allPosts,
              hasNextPage: pagedResult.metadata.hasNextPage,
              hasReachedMax:
                  pagedResult.items.length < event.limit ||
                  !pagedResult.metadata.hasNextPage,
              page: event.page,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PostsStatus.failure,
          errorMessage: "Unexpected error: $e",
        ),
      );
    }
  }

  Future<void> _onGetUserPosts(
    GetUserPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
    try {
      if (state.status == PostsStatus.loading) return;
      if (!state.hasNextPage && !event.isRefresh && event.page != 1) return;

      emit(
        state.copyWith(
          status: PostsStatus.loading,
          posts: event.isRefresh ? [] : state.posts,
        ),
      );

      final result = await getUserPosts(
        GetUserPostsParams(
          userId: event.userId,
          page: event.page,
          limit: event.limit,
        ),
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: PostsStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (PagedResult<PostEntity> pagedResult) {
          final List<PostEntity> allPosts = event.isRefresh
              ? []
              : List<PostEntity>.from(state.posts);

          allPosts.addAll(pagedResult.items);

          emit(
            state.copyWith(
              status: PostsStatus.success,
              posts: allPosts,
              hasNextPage: pagedResult.metadata.hasNextPage,
              hasReachedMax:
                  pagedResult.items.length < event.limit ||
                  !pagedResult.metadata.hasNextPage,
              page: event.page,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PostsStatus.failure,
          errorMessage: "Unexpected error: $e",
        ),
      );
    }
  }

  Future<void> _onDeletePost(
    DeletePostEvent event,
    Emitter<PostsState> emit,
  ) async {
    final previousPosts = List.of(state.posts);
    try {
      // Optimistic Update: Remove locally first
      final updatedPosts = List.of(state.posts)
        ..removeWhere((p) => p.id == event.postId);

      emit(state.copyWith(posts: updatedPosts));

      final result = await deletePost(DeletePostParams(id: event.postId));

      result.fold(
        (failure) {
          // Revert if failed
          emit(
            state.copyWith(
              status: PostsStatus.failure,
              posts: previousPosts,
              errorMessage: failure.message,
            ),
          );
        },
        (_) {
          // Success - nothing to do as we already removed it
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PostsStatus.failure,
          posts: previousPosts,
          errorMessage: "Unexpected error: $e",
        ),
      );
    }
  }

  Future<void> _onLikePost(
    LikePostEvent event,
    Emitter<PostsState> emit,
  ) async {
    final originalPosts = List<PostEntity>.from(state.posts);

    try {
      // Optimistic Update
      final updatedPosts = state.posts.map((post) {
        if (post.id == event.postId) {
          final isLiked = !post.isLiked;
          return post.copyWith(
            isLiked: isLiked,
            likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
          );
        }
        return post;
      }).toList();

      emit(state.copyWith(posts: updatedPosts));

      // Call UseCase
      final isLiked = updatedPosts
          .firstWhere((p) => p.id == event.postId)
          .isLiked;
      final result = await likePost(
        LikePostParams(postId: event.postId, isLiked: isLiked),
      );

      result.fold(
        (failure) {
          // Revert on failure
          emit(
            state.copyWith(posts: originalPosts, errorMessage: failure.message),
          );
        },
        (_) => null, // Success: already updated optimistically
      );
    } catch (e) {
      emit(
        state.copyWith(
          posts: originalPosts,
          errorMessage: "Unexpected error: $e",
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _appSessionUserIdSubscription?.cancel();
    return super.close();
  }
}
