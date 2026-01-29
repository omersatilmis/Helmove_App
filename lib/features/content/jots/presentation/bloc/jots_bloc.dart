import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_jot_usecase.dart';
import '../../domain/usecases/delete_jot_usecase.dart';
import '../../domain/usecases/get_user_jots_usecase.dart';
import 'jots_event.dart';
import 'jots_state.dart';

class JotsBloc extends Bloc<JotsEvent, JotsState> {
  final GetUserJotsUseCase getUserJots;
  final CreateJotUseCase createJot;
  final DeleteJotUseCase deleteJot;

  JotsBloc({
    required this.getUserJots,
    required this.createJot,
    required this.deleteJot,
  }) : super(const JotsState()) {
    on<FetchUserJotsEvent>(_onFetchUserJots);
    on<FetchMoreUserJotsEvent>(_onFetchMoreUserJots);
    on<CreateJotEvent>(_onCreateJot);
    on<DeleteJotEvent>(_onDeleteJot);
  }

  Future<void> _onFetchUserJots(
    FetchUserJotsEvent event,
    Emitter<JotsState> emit,
  ) async {
    // Eğer zaten veri yüklendiyse ve bu bir yenileme (refresh) değilse tekrar çekme
    if (!event.isRefresh && state.status == JotsStatus.success) return;

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
      emit(state.copyWith(status: JotsStatus.loading));
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
        state.isFetchingMore) {
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
        state.copyWith(errorMessage: failure.message, isFetchingMore: false),
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
}
