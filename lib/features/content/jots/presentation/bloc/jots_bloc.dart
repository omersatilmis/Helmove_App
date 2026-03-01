import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_jot_usecase.dart';
import '../../domain/usecases/delete_jot_usecase.dart';
import '../../domain/usecases/get_user_jots_usecase.dart';
import '../../domain/usecases/like_jot_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import 'jots_event.dart';
import 'jots_state.dart';

class JotsBloc extends Bloc<JotsEvent, JotsState> {
  final GetUserJotsUseCase getUserJots;
  final GetJotsFeedUseCase getFeed;
  final CreateJotUseCase createJot;
  final DeleteJotUseCase deleteJot;
  final LikeJotUseCase likeJot;

  static const int _defaultPageSize = 10;

  JotsBloc({
    required this.getUserJots,
    required this.getFeed,
    required this.createJot,
    required this.deleteJot,
    required this.likeJot,
  }) : super(const JotsState()) {
    on<FetchUserJotsEvent>(_onFetchUserJots);
    on<FetchMoreUserJotsEvent>(_onFetchMoreUserJots);
    on<FetchJotsFeedEvent>(_onFetchJotsFeed);
    on<FetchMoreJotsFeedEvent>(_onFetchMoreJotsFeed);
    on<CreateJotEvent>(_onCreateJot);
    on<DeleteJotEvent>(_onDeleteJot);
    on<LikeJotEvent>(_onLikeJot);
  }

  Future<void> _onFetchUserJots(
    FetchUserJotsEvent event,
    Emitter<JotsState> emit,
  ) async {
    // Eğer zaten veri yüklendiyse ve bu bir yenileme (refresh) değilse tekrar çekme
    if (!event.isRefresh &&
        state.status == JotsStatus.success &&
        state.source == JotsSource.profile) {
      return;
    }

    // Refresh ise listeyi temizle
    if (event.isRefresh) {
      emit(
        state.copyWith(
          status: JotsStatus.loading,
          jots: [],
          currentPage: 1,
          hasReachedMax: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: JotsStatus.loading,
          source: JotsSource.profile,
        ),
      );
    }

    final result = await getUserJots(
      GetUserJotsParams(userId: event.userId, page: 1),
    );

    result.fold(
      (failure) {
        debugPrint('❌ [JotsBloc] Fetch failed: ${failure.message}');
        emit(
          state.copyWith(
            status: JotsStatus.failure,
            errorMessage: failure.message,
            source: JotsSource.profile,
          ),
        );
      },
      (jots) {
        debugPrint(
          '✅ [JotsBloc] Fetched ${jots.length} jots for user ${event.userId}',
        );
        emit(
          state.copyWith(
            status: JotsStatus.success,
            jots: jots,
            hasReachedMax: jots.isEmpty,
            currentPage: 1,
            source: JotsSource.profile,
          ),
        );
      },
    );
  }

  Future<void> _onFetchMoreUserJots(
    FetchMoreUserJotsEvent event,
    Emitter<JotsState> emit,
  ) async {
    // Eğer zaten max'a ulaşılmışsa, hata varsa veya ŞU AN YÜKLENİYORSA işlem yapma
    if (state.hasReachedMax ||
        state.status != JotsStatus.success ||
        state.isFetchingMore ||
        state.source != JotsSource.profile) {
      return;
    }

    // Yükleniyor durumuna çek
    emit(state.copyWith(isFetchingMore: true));

    final nextPage = state.currentPage + 1;

    final result = await getUserJots(
      GetUserJotsParams(userId: event.userId, page: nextPage),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isFetchingMore: false,
          source: JotsSource.profile,
        ),
      ),
      (newJots) {
        if (newJots.isEmpty) {
          emit(state.copyWith(hasReachedMax: true, isFetchingMore: false));
        } else {
          emit(
            state.copyWith(
              jots: List.of(state.jots)..addAll(newJots),
              currentPage: nextPage,
              hasReachedMax: false,
              isFetchingMore: false,
              source: JotsSource.profile,
            ),
          );
        }
      },
    );
  }

  Future<void> _onFetchJotsFeed(
    FetchJotsFeedEvent event,
    Emitter<JotsState> emit,
  ) async {
    final shouldRefetch = event.isRefresh || state.source != JotsSource.feed;
    if (!shouldRefetch && state.status == JotsStatus.success) {
      return;
    }

    emit(
      state.copyWith(
        status: JotsStatus.loading,
        jots: shouldRefetch ? [] : state.jots,
        currentPage: 1,
        hasReachedMax: false,
        source: JotsSource.feed,
      ),
    );

    final result = await getFeed(const GetFeedParams(page: 1));

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: JotsStatus.failure,
          errorMessage: failure.message,
          source: JotsSource.feed,
        ),
      ),
      (jots) => emit(
        state.copyWith(
          status: JotsStatus.success,
          jots: jots,
          currentPage: 1,
          hasReachedMax: jots.length < _defaultPageSize,
          source: JotsSource.feed,
        ),
      ),
    );
  }

  Future<void> _onFetchMoreJotsFeed(
    FetchMoreJotsFeedEvent event,
    Emitter<JotsState> emit,
  ) async {
    if (state.source != JotsSource.feed ||
        state.hasReachedMax ||
        state.status != JotsStatus.success ||
        state.isFetchingMore) {
      return;
    }

    emit(state.copyWith(isFetchingMore: true));

    final nextPage = state.currentPage + 1;
    final result = await getFeed(GetFeedParams(page: nextPage));

    result.fold(
      (failure) => emit(
        state.copyWith(
          errorMessage: failure.message,
          isFetchingMore: false,
          source: JotsSource.feed,
        ),
      ),
      (newJots) {
        if (newJots.isEmpty) {
          emit(
            state.copyWith(
              hasReachedMax: true,
              isFetchingMore: false,
            ),
          );
        } else {
          emit(
            state.copyWith(
              jots: List.of(state.jots)..addAll(newJots),
              currentPage: nextPage,
              hasReachedMax: newJots.length < _defaultPageSize,
              isFetchingMore: false,
              source: JotsSource.feed,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCreateJot(
    CreateJotEvent event,
    Emitter<JotsState> emit,
  ) async {
    emit(state.copyWith(createStatus: JotsStatus.loading));

    final result = await createJot(
      CreateJotParams(
        type: event.type,
        text: event.text,
        mediaUrl: event.mediaUrl,
        visibility: event.visibility,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          createStatus: JotsStatus.failure,
          createError: failure.message,
        ),
      ),
      (newJot) {
        // Optimistic UI: Yeni Jot'u listenin başına ekle
        final updatedList = List.of(state.jots)..insert(0, newJot);
        emit(
          state.copyWith(createStatus: JotsStatus.success, jots: updatedList),
        );
      },
    );
  }

  Future<void> _onDeleteJot(
    DeleteJotEvent event,
    Emitter<JotsState> emit,
  ) async {
    // Optimistic UI: Önce listeden sil
    final previousJots = List.of(state.jots);
    final updatedList = List.of(state.jots)
      ..removeWhere((jot) => jot.id == event.jotId);

    emit(state.copyWith(jots: updatedList));

    final result = await deleteJot(DeleteJotParams(id: event.jotId));

    result.fold(
      (failure) {
        // Hata olursa geri al
        emit(
          state.copyWith(
            jots: previousJots,
            errorMessage: "Silme işlemi başarısız",
          ),
        );
      },
      (_) {
        // Başarılı, zaten sildik
      },
    );
  }

  Future<void> _onLikeJot(LikeJotEvent event, Emitter<JotsState> emit) async {
    // Current state of the jot
    final jot = state.jots.firstWhere((j) => j.id == event.jotId);

    // Optimistic UI Update can be added here
    final result = await likeJot(
      LikeJotParams(id: event.jotId, isLiked: jot.isLiked),
    );

    result.fold((failure) {
      // Handle failure if needed
    }, (_) {});
  }
}
