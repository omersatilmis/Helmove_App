import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/app_session.dart';
import '../../../../auth/domain/usecases/get_current_user_id_use_case.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import '../../domain/usecases/get_user_posts_usecase.dart';
import '../../domain/usecases/like_post_usecase.dart';
import '../../domain/entities/post_entity.dart';
import '../../data/cache/post_feed_cache.dart';
import 'posts_event.dart';
import 'posts_state.dart';

import '../../../../../core/models/paged_result.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  static const int _cachePageSize = 10;

  final GetPostsFeedUseCase getFeed;
  final GetUserPostsUseCase getUserPosts;
  final DeletePostUseCase deletePost;
  final LikePostUseCase likePost;
  final GetCurrentUserIdUseCase getCurrentUserIdUseCase;
  final AppSession appSession;
  final PostFeedCache postFeedCache;
  StreamSubscription<int?>? _appSessionUserIdSubscription;

  PostsBloc({
    required this.getFeed,
    required this.getUserPosts,
    required this.deletePost,
    required this.likePost,
    required this.getCurrentUserIdUseCase,
    required this.appSession,
    required this.postFeedCache,
  }) : super(const PostsState()) {
    on<GetFeedEvent>(_onGetFeed);
    on<GetUserPostsEvent>(_onGetUserPosts);
    on<DeletePostEvent>(_onDeletePost);
    on<LikePostEvent>(_onLikePost);
    on<PostsCurrentUserChangedEvent>(_onPostsCurrentUserChanged);
    on<SeedInitialFeedEvent>(_onSeedInitialFeed);

    Future.microtask(_initializeCurrentUserBridge);
  }

  Future<void> _initializeCurrentUserBridge() async {
    final userId = appSession.currentUserId ?? await getCurrentUserIdUseCase();
    if (!isClosed) {
      add(PostsCurrentUserChangedEvent(userId));
    }

    _appSessionUserIdSubscription = appSession.currentUserIdStream
        .distinct()
        .listen((userId) {
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

  void _onSeedInitialFeed(
    SeedInitialFeedEvent event,
    Emitter<PostsState> emit,
  ) {
    if (event.posts.isEmpty) {
      return;
    }
    if (state.posts.isNotEmpty) {
      return;
    }

    emit(
      state.copyWith(
        status: PostsStatus.success,
        posts: event.posts,
        hasNextPage: event.hasNextPage,
        hasReachedMax: !event.hasNextPage,
        page: event.page,
      ),
    );
  }

  Future<void> _onGetFeed(GetFeedEvent event, Emitter<PostsState> emit) async {
    try {
      // Prevent duplicate requests if already loading or reached max/has no more pages
      if (state.status == PostsStatus.loading) return;
      if (state.hasReachedMax && !event.isRefresh && event.page != 1) return;
      // Guard: avoid double-fetch on startup if we already have data in memory.
      if (event.page == 1 && !event.isRefresh && state.posts.isNotEmpty) {
        return;
      }

      final currentUserId = state.currentUserId ?? appSession.currentUserId;
      final shouldLoadFromCache =
          event.page == 1 && !event.isRefresh && state.posts.isEmpty;
      var cacheApplied = false;
      PostFeedCacheSnapshot? firstPageSnapshot;

      if (event.page == 1) {
        firstPageSnapshot = await postFeedCache.readFirstPage(
          userId: currentUserId,
          limit: event.limit,
        );
      }

      if (shouldLoadFromCache) {
        final cached = firstPageSnapshot;
        if (cached != null && cached.posts.isNotEmpty) {
          cacheApplied = true;
          emit(
            state.copyWith(
              status: PostsStatus.success,
              posts: cached.posts,
              hasNextPage: cached.hasNextPage,
              hasReachedMax: !cached.hasNextPage,
              page: 1,
            ),
          );
          // Cache applied, we emit the state so the user sees data instantly.
          // BUT, we DO NOT return here! We let the execution continue
          // to make silent network call for ETag validation/updates.
        }
      }

      if (!cacheApplied) {
        emit(
          state.copyWith(
            status: PostsStatus.loading,
            posts: event.isRefresh ? [] : state.posts,
          ),
        );
      }

      final result = await getFeed(
        GetFeedParams(
          page: event.page,
          limit: event.limit,
          ifNoneMatch: event.page == 1 ? firstPageSnapshot?.etag : null,
        ),
      );

      result.fold(
        (failure) {
          if (cacheApplied) {
            emit(state.copyWith(status: PostsStatus.success));
            return;
          }
          emit(
            state.copyWith(
              status: PostsStatus.failure,
              errorMessage: failure.message,
            ),
          );
        },
        (fetchResult) {
          if (fetchResult.notModified) {
            final cached = firstPageSnapshot;
            if (cached != null) {
              emit(
                state.copyWith(
                  status: PostsStatus.success,
                  posts: cached.posts,
                  hasNextPage: cached.hasNextPage,
                  hasReachedMax: !cached.hasNextPage,
                  page: 1,
                ),
              );
            } else if (cacheApplied) {
              emit(state.copyWith(status: PostsStatus.success));
            } else {
              emit(
                state.copyWith(
                  status: PostsStatus.failure,
                  errorMessage: 'Feed not modified but no cache is available.',
                ),
              );
            }
            return;
          }

          final pagedResult = fetchResult.data;
          if (pagedResult == null) {
            if (cacheApplied) {
              emit(state.copyWith(status: PostsStatus.success));
              return;
            }
            emit(
              state.copyWith(
                status: PostsStatus.failure,
                errorMessage: 'Feed response is empty.',
              ),
            );
            return;
          }

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

          if (event.page == 1 && event.limit == _cachePageSize) {
            unawaited(
              postFeedCache.writeFirstPage(
                userId: currentUserId,
                posts: allPosts,
                hasNextPage: pagedResult.metadata.hasNextPage,
                etag: fetchResult.etag,
                limit: event.limit,
              ),
            );
          }
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
      _syncFirstPageCacheIfPossible(updatedPosts);

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
      _syncFirstPageCacheIfPossible(updatedPosts);

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

  void _syncFirstPageCacheIfPossible(List<PostEntity> posts) {
    if (state.page != 1 || posts.isEmpty) {
      return;
    }

    final currentUserId = state.currentUserId ?? appSession.currentUserId;
    unawaited(_writeFirstPageCache(currentUserId: currentUserId, posts: posts));
  }

  Future<void> _writeFirstPageCache({
    required int? currentUserId,
    required List<PostEntity> posts,
  }) async {
    final existingCache = await postFeedCache.readFirstPage(
      userId: currentUserId,
      limit: _cachePageSize,
    );
    await postFeedCache.writeFirstPage(
      userId: currentUserId,
      posts: posts,
      hasNextPage: state.hasNextPage,
      etag: existingCache?.etag,
      limit: _cachePageSize,
    );
  }

  @override
  Future<void> close() {
    _appSessionUserIdSubscription?.cancel();
    return super.close();
  }
}
