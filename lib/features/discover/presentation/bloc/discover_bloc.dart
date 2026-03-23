import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/get_explore_usecase.dart';
import '../../../content/posts/domain/entities/post_entity.dart';
import 'discover_event.dart';
import 'discover_state.dart';

class DiscoverBloc extends Bloc<DiscoverEvent, DiscoverState> {
  final SearchUsersUseCase searchUsers;
  final GetExploreUseCase getExplore;

  DiscoverBloc({required this.searchUsers, required this.getExplore})
    : super(DiscoverInitial()) {
    on<SearchUsersEvent>(_onSearchUsers);
    on<LoadDiscoveryContent>(_onLoadDiscoveryContent);
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
