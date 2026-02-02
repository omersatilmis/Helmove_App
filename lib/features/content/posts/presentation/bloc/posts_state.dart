import 'package:equatable/equatable.dart';
import '../../domain/entities/post_entity.dart';

enum PostsStatus { initial, loading, success, failure }

class PostsState extends Equatable {
  final PostsStatus status;
  final List<PostEntity> posts;
  final bool hasReachedMax; // Keep for backward compatibility or UI checks
  final bool hasNextPage;
  final String? errorMessage;
  final int page;

  const PostsState({
    this.status = PostsStatus.initial,
    this.posts = const [],
    this.hasReachedMax = false,
    this.hasNextPage = true,
    this.errorMessage,
    this.page = 1,
  });

  PostsState copyWith({
    PostsStatus? status,
    List<PostEntity>? posts,
    bool? hasReachedMax,
    bool? hasNextPage,
    String? errorMessage,
    int? page,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      errorMessage: errorMessage ?? this.errorMessage,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [
    status,
    posts,
    hasReachedMax,
    hasNextPage,
    errorMessage,
    page,
  ];
}
