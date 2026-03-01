import 'package:equatable/equatable.dart';
import '../../domain/entities/jot_entity.dart';

enum JotsStatus { initial, loading, success, failure }

enum JotsSource { profile, feed }

class JotsState extends Equatable {
  final JotsStatus status;
  final List<JotEntity> jots;
  final bool hasReachedMax;
  final int currentPage;
  final String errorMessage;
  // Creation status
  final JotsStatus createStatus;
  final String createError;
  final JotsSource source;

  const JotsState({
    this.status = JotsStatus.initial,
    this.jots = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.errorMessage = "",
    this.createStatus = JotsStatus.initial,
    this.createError = "",
    this.isFetchingMore = false,
    this.source = JotsSource.profile,
  });

  final bool isFetchingMore;

  JotsState copyWith({
    JotsStatus? status,
    List<JotEntity>? jots,
    bool? hasReachedMax,
    int? currentPage,
    String? errorMessage,
    JotsStatus? createStatus,
    String? createError,
    bool? isFetchingMore,
    JotsSource? source,
  }) {
    return JotsState(
      status: status ?? this.status,
      jots: jots ?? this.jots,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
      createStatus: createStatus ?? this.createStatus,
      createError: createError ?? this.createError,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [
    status,
    jots,
    hasReachedMax,
    currentPage,
    errorMessage,
    createStatus,
    createError,
    isFetchingMore,
    source,
  ];
}
