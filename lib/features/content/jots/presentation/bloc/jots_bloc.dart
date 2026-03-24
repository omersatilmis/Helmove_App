import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../auth/domain/usecases/get_current_user_id_use_case.dart';
import 'package:helmove/core/services/app_session.dart';
import '../../../../media/domain/usecases/upload_image_usecase.dart';
import '../../domain/entities/jot_entity.dart';
import '../../domain/usecases/create_jot_usecase.dart';
import '../../domain/usecases/delete_jot_usecase.dart';
import '../../domain/usecases/get_user_jots_usecase.dart';
import '../../domain/usecases/like_jot_usecase.dart';
import '../../domain/usecases/get_feed_usecase.dart';
import 'jots_event.dart';
import 'jots_state.dart';
import '../../data/cache/jot_feed_cache.dart';

class JotsBloc extends Bloc<JotsEvent, JotsState> {
  final GetUserJotsUseCase getUserJots;
  final GetJotsFeedUseCase getFeed;
  final CreateJotUseCase createJot;
  final DeleteJotUseCase deleteJot;
  final LikeJotUseCase likeJot;
  final JotFeedCache jotFeedCache;
  final UploadImageUseCase uploadImage;
  final AppSession appSession;
  final GetCurrentUserIdUseCase getCurrentUserIdUseCase;

  StreamSubscription<int?>? _appSessionUserIdSubscription;

  static const int _defaultPageSize = 10;

  JotsBloc({
    required this.getUserJots,
    required this.getFeed,
    required this.createJot,
    required this.deleteJot,
    required this.likeJot,
    required this.jotFeedCache,
    required this.uploadImage,
    required this.appSession,
    required this.getCurrentUserIdUseCase,
  }) : super(const JotsState()) {
    on<FetchUserJotsEvent>(_onFetchUserJots);
    on<FetchMoreUserJotsEvent>(_onFetchMoreUserJots);
    on<FetchJotsFeedEvent>(_onFetchJotsFeed);
    on<FetchMoreJotsFeedEvent>(_onFetchMoreJotsFeed);
    on<CreateJotEvent>(_onCreateJot);
    on<DeleteJotEvent>(_onDeleteJot);
    on<LikeJotEvent>(_onLikeJot);
    on<JotsCurrentUserChangedEvent>(_onJotsCurrentUserChanged);

    // Initialize bridge
    Future.microtask(_initializeCurrentUserBridge);
  }

  Future<void> _initializeCurrentUserBridge() async {
    final userId = appSession.currentUserId ?? await getCurrentUserIdUseCase();
    if (!isClosed) {
      add(JotsCurrentUserChangedEvent(currentUserId: userId));
    }

    _appSessionUserIdSubscription = appSession.currentUserIdStream.listen((id) {
      if (!isClosed) {
        add(JotsCurrentUserChangedEvent(currentUserId: id));
      }
    });
  }

  void _onJotsCurrentUserChanged(
    JotsCurrentUserChangedEvent event,
    Emitter<JotsState> emit,
  ) {
    emit(state.copyWith(currentUserId: event.currentUserId));
  }

  @override
  Future<void> close() {
    _appSessionUserIdSubscription?.cancel();
    return super.close();
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
            errorMessage: "Silme işlemi başarısız: ${failure.message}",
          ),
        );
      },
      (_) {
        // Başarılı, cache'i güncelle
        syncFirstPageCacheIfPossible(updatedList);
      },
    );
  }

  Future<void> _onLikeJot(
    LikeJotEvent event,
    Emitter<JotsState> emit,
  ) async {
    final originalJots = List<JotEntity>.from(state.jots);

    try {
      // Optimistic UI Update
      final updatedJots = state.jots.map((jot) {
        if (jot.id == event.jotId) {
          final isLiked = !jot.isLiked;
          return jot.copyWith(
            isLiked: isLiked,
            likeCount: isLiked ? jot.likeCount + 1 : jot.likeCount - 1,
          );
        }
        return jot;
      }).toList();

      emit(state.copyWith(jots: updatedJots));

      // Update cache silently
      syncFirstPageCacheIfPossible(updatedJots);

      // Current state of the jot (after optimistic update)
      final isLiked = updatedJots
          .firstWhere((j) => j.id == event.jotId)
          .isLiked;

      final result = await likeJot(
        LikeJotParams(id: event.jotId, isLiked: isLiked),
      );

      result.fold(
        (failure) {
          // Revert on failure
          emit(
            state.copyWith(
              errorMessage: "Beğenme işlemi başarısız: ${failure.message}",
              jots: originalJots,
            ),
          );
          syncFirstPageCacheIfPossible(originalJots);
        },
        (_) => null, // Success
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: "Beklenmedik hata: $e",
          jots: originalJots,
        ),
      );
    }
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
        state.copyWith(status: JotsStatus.loading, source: JotsSource.profile),
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
      (pagedResult) {
        final jots = pagedResult.items;
        debugPrint(
          '✅ [JotsBloc] Fetched ${jots.length} jots for user ${event.userId}',
        );
        emit(
          state.copyWith(
            status: JotsStatus.success,
            jots: jots,
            hasReachedMax: jots.length < _defaultPageSize,
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
      (pagedResult) {
        final newJots = pagedResult.items;
        if (newJots.isEmpty) {
          emit(state.copyWith(hasReachedMax: true, isFetchingMore: false));
        } else {
          emit(
            state.copyWith(
              jots: List.of(state.jots)..addAll(newJots),
              currentPage: nextPage,
              hasReachedMax: newJots.length < _defaultPageSize,
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

    var cacheApplied = false;
    String? currentEtag;

    // Load from cache first if it's not a refresh and we don't have jots
    if (!event.isRefresh && state.jots.isEmpty) {
      final cachedSnapshot = await jotFeedCache.readFirstPage();
      if (cachedSnapshot != null && cachedSnapshot.jots.isNotEmpty) {
        cacheApplied = true;
        currentEtag = cachedSnapshot.etag;
        emit(
          state.copyWith(
            status: JotsStatus.success,
            jots: cachedSnapshot.jots,
            currentPage: 1,
            hasReachedMax: !cachedSnapshot.hasNextPage,
            source: JotsSource.feed,
          ),
        );
      }
    }

    if (!cacheApplied) {
      emit(
        state.copyWith(
          status: JotsStatus.loading,
          jots: event.isRefresh ? [] : state.jots,
          currentPage: 1,
          hasReachedMax: false,
          source: JotsSource.feed,
        ),
      );
    }

    // Silent background network call
    final result = await getFeed(
      GetFeedParams(page: 1, limit: _defaultPageSize, ifNoneMatch: currentEtag),
    );

    result.fold(
      (failure) {
        if (!cacheApplied) {
          emit(
            state.copyWith(
              status: JotsStatus.failure,
              errorMessage: failure.message,
              source: JotsSource.feed,
            ),
          );
        }
      },
      (fetchResult) {
        if (fetchResult.notModified) {
          debugPrint('✅ [JotsBloc] Feed not modified (304). Keeping cache.');
          return;
        }

        final jots = fetchResult.data?.items ?? [];
        final hasReachedMax = jots.length < _defaultPageSize;
        emit(
          state.copyWith(
            status: JotsStatus.success,
            jots: jots,
            currentPage: 1,
            hasReachedMax: hasReachedMax,
            source: JotsSource.feed,
          ),
        );

        // Update cache secretly
        jotFeedCache.writeFirstPage(
          jots: jots,
          hasNextPage: !hasReachedMax,
          limit: _defaultPageSize,
          etag: fetchResult.etag,
        );
      },
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
      (fetchResult) {
        final newJots = fetchResult.data?.items ?? [];
        if (newJots.isEmpty) {
          emit(state.copyWith(hasReachedMax: true, isFetchingMore: false));
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

    String? finalMediaUrl = event.mediaUrl;

    // Eğer mediaUrl bir dosya yolu ise (http ile başlamıyorsa), önce yükle
    if (finalMediaUrl != null &&
        finalMediaUrl.isNotEmpty &&
        !finalMediaUrl.startsWith('http')) {
      final file = File(finalMediaUrl);
      if (file.existsSync()) {
      debugPrint('📸 [JotsBloc] Uploading image: ${file.path}');
      final uploadResult = await uploadImage(file);
      
      bool uploadFailed = false;
      String? failureMessage;

      uploadResult.fold(
        (failure) {
          debugPrint('❌ [JotsBloc] Upload failed: ${failure.message}');
          uploadFailed = true;
          failureMessage = failure.message;
        },
        (url) {
          finalMediaUrl = url;
          debugPrint('✅ [JotsBloc] Image uploaded success: $url');
        },
      );

      if (uploadFailed) {
        emit(
          state.copyWith(
            createStatus: JotsStatus.failure,
            createError: failureMessage ?? 'Resim yüklenirken hata oluştu',
          ),
        );
        return;
      }
    }
  }

    final result = await createJot(
      CreateJotParams(
        type: event.type,
        text: event.text,
        mediaUrl: finalMediaUrl,
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
        // Yeni Jot'u listenin başına ekle
        final updatedList = List.of(state.jots)..insert(0, newJot);
        emit(
          state.copyWith(createStatus: JotsStatus.success, jots: updatedList),
        );
      },
    );
  }

  Future<void> syncFirstPageCacheIfPossible(List<JotEntity> jots) async {
    if (state.currentPage != 1 || jots.isEmpty) {
      return;
    }

    await jotFeedCache.writeFirstPage(
      jots: jots,
      hasNextPage: !state.hasReachedMax,
      limit: _defaultPageSize,
    );
  }
}
