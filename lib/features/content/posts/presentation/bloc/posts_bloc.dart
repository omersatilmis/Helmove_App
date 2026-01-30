import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import '../../domain/usecases/get_user_posts_usecase.dart';
import 'posts_event.dart';
import 'posts_state.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final GetFeedUseCase getFeed;
  final GetUserPostsUseCase getUserPosts;
  final DeletePostUseCase deletePost;

  PostsBloc({
    required this.getFeed,
    required this.getUserPosts,
    required this.deletePost,
  }) : super(const PostsState()) {
    on<GetFeedEvent>(_onGetFeed);
    on<GetUserPostsEvent>(_onGetUserPosts);
    on<DeletePostEvent>(_onDeletePost);
  }

  Future<void> _onGetFeed(GetFeedEvent event, Emitter<PostsState> emit) async {
    if (state.hasReachedMax && !event.isRefresh && event.page != 1) return;

    if (state.status == PostsStatus.initial || event.isRefresh) {
      emit(
        state.copyWith(
          status: PostsStatus.loading,
          posts: event.isRefresh ? [] : state.posts,
        ),
      );
    }

    final result = await getFeed(GetFeedParams(page: event.page));

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
            hasReachedMax: posts.isEmpty,
            page: event.page,
          ),
        );
      },
    );
  }

  Future<void> _onGetUserPosts(
    GetUserPostsEvent event,
    Emitter<PostsState> emit,
  ) async {
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
      GetUserPostsParams(userId: event.userId, page: event.page),
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
            hasReachedMax: posts.isEmpty,
            page: event.page,
          ),
        );
      },
    );
  }

  Future<void> _onDeletePost(
    DeletePostEvent event,
    Emitter<PostsState> emit,
  ) async {
    // Optimistic Update: Remove locally first
    final previousPosts = List.of(state.posts);
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
  }
}
