import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/app_session.dart';
import '../../../../core/services/post_like_sync_bus.dart';
import '../../../content/posts/data/cache/post_feed_cache.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/get_explore_usecase.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../../../content/posts/domain/usecases/like_post_usecase.dart';
import '../../../content/posts/presentation/bloc/posts_bloc.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final SearchUsersUseCase searchUsers;
  final GetExploreUseCase getExplore;
  final LikePostUseCase likePost;
  bool _isDiscoveryRequestInFlight = false;
  final Set<int> _likeRequestsInFlight = <int>{};
  StreamSubscription<PostLikeSyncPayload>? _postLikeSyncSubscription;

  DiscoverBloc({
    required this.searchUsers,
    required this.getExplore,
    required this.likePost,
  }) : super(DiscoverInitial()) {
    on<SearchUsersEvent>(_onSearchUsers);
    on<LoadDiscoveryContent>(_onLoadDiscoveryContent);
    on<ToggleDiscoverPostLikeEvent>(_onToggleLikePost);
    on<SyncDiscoverPostLikeStateEvent>(_onSyncDiscoverPostLikeState);
    on<LocalDeleteDiscoverPostEvent>(_onLocalDeletePost);
    on<AdjustDiscoverPostCommentCountEvent>(_onAdjustCommentCount);

    _postLikeSyncSubscription = PostLikeSyncBus.instance.stream.listen((payload) {
      if (payload.origin == PostLikeSyncOrigin.discover || isClosed) {
        return;
      }

      add(
        SyncDiscoverPostLikeStateEvent(
          postId: payload.postId,
          isLiked: payload.isLiked,
          likeCount: payload.likeCount,
        ),
      );
    });
  }

  Future<void> _onToggleLikePost(
    ToggleDiscoverPostLikeEvent event,
    Emitter<DiscoverState> emit,
  ) async {
    if (_likeRequestsInFlight.contains(event.postId)) {
      return;
    }

    if (state is! DiscoverDiscoveryLoaded) {
      return;
    }

    final loadedState = state as DiscoverDiscoveryLoaded;
    final currentPostIndex = loadedState.content.indexWhere(
      (post) => post.id == event.postId,
    );

    if (currentPostIndex < 0) {
      return;
    }

    final currentPost = loadedState.content[currentPostIndex];

    final optimisticIsLiked = !currentPost.isLiked;
    final optimisticLikeCount = optimisticIsLiked
        ? currentPost.likeCount + 1
        : (currentPost.likeCount > 0 ? currentPost.likeCount - 1 : 0);

    final optimisticContent = loadedState.content.map((post) {
      if (post.id != event.postId) {
        return post;
      }
      return post.copyWith(
        isLiked: optimisticIsLiked,
        likeCount: optimisticLikeCount,
      );
    }).toList();

    _likeRequestsInFlight.add(event.postId);
    try {
      emit(loadedState.copyWith(content: optimisticContent));
      PostLikeSyncBus.instance.emit(
        PostLikeSyncPayload(
          postId: event.postId,
          isLiked: optimisticIsLiked,
          likeCount: optimisticLikeCount,
          origin: PostLikeSyncOrigin.discover,
        ),
      );

      final result = await likePost(
        LikePostParams(postId: event.postId, isLiked: optimisticIsLiked),
      );

      result.fold(
        (_) {
          final latestState = state;
          if (latestState is! DiscoverDiscoveryLoaded) {
            return;
          }

          final rollbackContent = latestState.content.map((post) {
            if (post.id != event.postId) {
              return post;
            }
            return post.copyWith(
              isLiked: currentPost.isLiked,
              likeCount: currentPost.likeCount,
            );
          }).toList();

          emit(latestState.copyWith(content: rollbackContent));
          PostLikeSyncBus.instance.emit(
            PostLikeSyncPayload(
              postId: event.postId,
              isLiked: currentPost.isLiked,
              likeCount: currentPost.likeCount,
              origin: PostLikeSyncOrigin.discover,
            ),
          );
        },
        (_) {},
      );
    } finally {
      _likeRequestsInFlight.remove(event.postId);
    }
  }

  void _onLocalDeletePost(
    LocalDeleteDiscoverPostEvent event,
    Emitter<DiscoverState> emit,
  ) {
    if (state is DiscoverDiscoveryLoaded) {
      final loadedState = state as DiscoverDiscoveryLoaded;
      final updatedContent = loadedState.content.where((p) => p.id != event.postId).toList();
      emit(loadedState.copyWith(content: updatedContent));
    }
  }

  void _onSyncDiscoverPostLikeState(
    SyncDiscoverPostLikeStateEvent event,
    Emitter<DiscoverState> emit,
  ) {
    if (state is! DiscoverDiscoveryLoaded) {
      return;
    }

    final loadedState = state as DiscoverDiscoveryLoaded;
    var changed = false;
    final updatedContent = loadedState.content.map((post) {
      if (post.id != event.postId) {
        return post;
      }

      changed = true;
      return post.copyWith(isLiked: event.isLiked, likeCount: event.likeCount);
    }).toList();

    if (!changed) {
      return;
    }

    emit(loadedState.copyWith(content: updatedContent));
  }

  void _onAdjustCommentCount(
    AdjustDiscoverPostCommentCountEvent event,
    Emitter<DiscoverState> emit,
  ) {
    if (event.delta == 0 || state is! DiscoverDiscoveryLoaded) {
      return;
    }

    final loadedState = state as DiscoverDiscoveryLoaded;
    final updatedContent = loadedState.content.map((post) {
      if (post.id != event.postId) {
        return post;
      }
      final nextCount = post.commentCount + event.delta;
      return post.copyWith(commentCount: nextCount < 0 ? 0 : nextCount);
    }).toList();

    emit(loadedState.copyWith(content: updatedContent));
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<DiscoverState> emit,
  ) async {
    if (event.query.length < 3) {
      emit(const DiscoverFailure("Lütfen en az 3 karakter giriniz."));
      return;
    }

    emit(DiscoverLoading());

    final result = await searchUsers(
      SearchUsersParams(query: event.query, city: event.city),
    );

    result.fold(
      (failure) => emit(DiscoverFailure(failure.message)),
      (results) => emit(DiscoverLoaded(results)),
    );
  }

  Future<void> _onLoadDiscoveryContent(
    LoadDiscoveryContent event,
    Emitter<DiscoverState> emit,
  ) async {
    final currentState = state;
    final isRefresh = event.isRefresh;

    if (_isDiscoveryRequestInFlight) {
      return;
    }

    // Zaten yükleniyorsa veya maksimuma ulaşıldıysa (ve refresh değilse) çık
    if (!isRefresh &&
        currentState is DiscoverDiscoveryLoaded &&
        currentState.hasReachedMax) {
      return;
    }

    int pageToFetch = 1;
    List<PostEntity> oldContent = [];

    if (!isRefresh && currentState is DiscoverDiscoveryLoaded) {
      pageToFetch = currentState.page + 1;
      oldContent = currentState.content;
    }

    final hasExistingContent =
        currentState is DiscoverDiscoveryLoaded &&
        currentState.content.isNotEmpty;

    // Sadece ilk yüklemede loading göster. Var olan içerik varken refresh/pagination arka planda akar.
    if ((isRefresh && !hasExistingContent) ||
        currentState is! DiscoverDiscoveryLoaded) {
      emit(DiscoverLoading());
    }

    _isDiscoveryRequestInFlight = true;
    try {
      final knownById = await _buildKnownPostStateMap();
      final result = await getExplore(
        GetExploreParams(page: pageToFetch, limit: 20),
      );

      result.fold(
        (failure) {
          final friendlyMessage = _normalizeFailureMessage(
            failure.message,
            fallbackMessage: 'Kesfet icerigi yuklenemedi.',
          );

          // Var olan içeriği transient hatalarda düşürmeyelim.
          if (currentState is DiscoverDiscoveryLoaded &&
              currentState.content.isNotEmpty) {
            return;
          }

          emit(DiscoverFailure(friendlyMessage));
        },
        (pagedResult) {
          final newItems = pagedResult.items;
          final mergedNewItems = _mergeWithKnownPostStates(
            incoming: newItems,
            knownById: knownById,
          );
          final hasReachedMax =
              !pagedResult.metadata.hasNextPage || newItems.isEmpty;

          emit(
            DiscoverDiscoveryLoaded(
              content: isRefresh ? mergedNewItems : oldContent + mergedNewItems,
              page: pageToFetch,
              hasReachedMax: hasReachedMax,
            ),
          );
        },
      );
    } finally {
      _isDiscoveryRequestInFlight = false;
    }
  }

  String _normalizeFailureMessage(
    String rawMessage, {
    required String fallbackMessage,
  }) {
    final cleaned = rawMessage
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();

    if (cleaned.isEmpty) {
      return fallbackMessage;
    }

    // Mojibake karakterler goruldugunde kullaniciya temiz fallback goster.
    if (cleaned.contains('\u00C3') ||
        cleaned.contains('\u00C5') ||
        cleaned.contains('\u00C4')) {
      return fallbackMessage;
    }

    return cleaned;
  }

  Future<Map<int, PostEntity>> _buildKnownPostStateMap() async {
    final knownById = <int, PostEntity>{};

    final appSession = sl<AppSession>();
    final cache = sl<PostFeedCache>();
    final cachedSnapshot = await cache.readFirstPage(
      userId: appSession.currentUserId,
      limit: 10,
    );

    if (cachedSnapshot != null) {
      for (final post in cachedSnapshot.posts) {
        knownById[post.id] = post;
      }
    }

    final livePosts = sl<PostsBloc>().state.posts;
    for (final post in livePosts) {
      // Live state should have priority over cache.
      knownById[post.id] = post;
    }

    return knownById;
  }

  List<PostEntity> _mergeWithKnownPostStates({
    required List<PostEntity> incoming,
    required Map<int, PostEntity> knownById,
  }) {
    if (knownById.isEmpty || incoming.isEmpty) {
      return incoming;
    }

    return incoming.map((post) {
      final known = knownById[post.id];
      if (known == null) {
        return post;
      }

      return post.copyWith(isLiked: known.isLiked, likeCount: known.likeCount);
    }).toList();
  }

  @override
  Future<void> close() {
    _postLikeSyncSubscription?.cancel();
    return super.close();
  }
}

