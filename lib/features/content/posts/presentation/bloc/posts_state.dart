import 'package:equatable/equatable.dart';
import '../../domain/entities/post_entity.dart';

enum PostsStatus { initial, loading, success, failure }

class PostsState extends Equatable {
  final PostsStatus status;
  final List<PostEntity> posts;
  final bool hasReachedMax;
  final String? errorMessage;
  final int page;

  const PostsState({
    this.status = PostsStatus.initial,
    this.posts = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.page = 1,
  });

  PostsState copyWith({
    PostsStatus? status,
    List<PostEntity>? posts,
    bool? hasReachedMax,
    String? errorMessage,
    int? page,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [status, posts, hasReachedMax, errorMessage, page];
}
