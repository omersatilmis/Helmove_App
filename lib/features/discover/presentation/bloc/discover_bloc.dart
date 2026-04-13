import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/get_explore_usecase.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import '../../../content/posts/domain/usecases/like_post_usecase.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final SearchUsersUseCase searchUsers;
  final GetExploreUseCase getExplore;
  final LikePostUseCase likePost;

  DiscoverBloc({
    required this.searchUsers,
    required this.getExplore,
    required this.likePost,
  }) : super(DiscoverInitial()) {
    on<SearchUsersEvent>(_onSearchUsers);
    on<LoadDiscoveryContent>(_onLoadDiscoveryContent);
    on<ToggleDiscoverPostLikeEvent>(_onToggleLikePost);
    on<LocalDeleteDiscoverPostEvent>(_onLocalDeletePost);
    on<AdjustDiscoverPostCommentCountEvent>(_onAdjustCommentCount);
  }

  Future<void> _onToggleLikePost(
    ToggleDiscoverPostLikeEvent event,
    Emitter<DiscoverState> emit,
  ) async {
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

    emit(loadedState.copyWith(content: optimisticContent));

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
      },
      (_) {},
    );
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
    bool isRefresh = event.isRefresh;

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

    // İlk yükleme veya refresh ise shimmer göster
    if (isRefresh || currentState is! DiscoverDiscoveryLoaded) {
      emit(DiscoverLoading());
    }

    final result = await getExplore(
      GetExploreParams(page: pageToFetch, limit: 20),
    );

    result.fold(
      (failure) => emit(DiscoverFailure(failure.message)),
      (pagedResult) {
        final newItems = pagedResult.items;
        final hasReachedMax = newItems.length < 20;

        emit(
          DiscoverDiscoveryLoaded(
            content: isRefresh ? newItems : oldContent + newItems,
            page: pageToFetch,
            hasReachedMax: hasReachedMax,
          ),
        );
      },
    );
  }
}

