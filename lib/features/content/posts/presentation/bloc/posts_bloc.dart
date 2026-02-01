import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import '../../domain/usecases/get_user_posts_usecase.dart';
import '../../domain/usecases/like_post_usecase.dart';
import '../../domain/entities/post_entity.dart';
import 'posts_event.dart';
import 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetPostsFeedUseCase getFeed;
  final GetUserPostsUseCase getUserPosts;
  final DeletePostUseCase deletePost;
  final LikePostUseCase likePost;

  PostsBloc({
    required this.getFeed,
    required this.getUserPosts,
    required this.deletePost,
    required this.likePost,
  }) : super(const PostsState()) {
    on<GetFeedEvent>(_onGetFeed);
    on<GetUserPostsEvent>(_onGetUserPosts);
    on<DeletePostEvent>(_onDeletePost);
    on<LikePostEvent>(_onLikePost);
  }

  Future<void> _onGetFeed(GetFeedEvent event, Emitter<PostsState> emit) async {
    try {
      // Prevent duplicate requests if already loading or reached max
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
        (newPosts) {
          final List<PostEntity> allPosts = event.isRefresh
              ? []
              : List<PostEntity>.from(state.posts);

          allPosts.addAll(newPosts);

          emit(
            state.copyWith(
              status: PostsStatus.success,
              posts: allPosts,
              hasReachedMax: newPosts.length < event.limit,
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
      if (state.hasReachedMax && !event.isRefresh && event.page != 1) return;

      if (state.status == PostsStatus.initial || event.isRefresh) {
        emit(
          state.copyWith(
            status: PostsStatus.loading,
            posts: event.isRefresh ? [] : state.posts,
          ),
        );
      }

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
        (posts) {
          final allPosts = event.isRefresh ? posts : List.of(state.posts)
            ..addAll(posts);
          emit(
            state.copyWith(
              status: PostsStatus.success,
              posts: allPosts,
              hasReachedMax: posts.length < event.limit,
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
}
