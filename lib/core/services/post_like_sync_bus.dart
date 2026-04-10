import 'dart:async';

enum PostLikeSyncOrigin { posts, discover }

class PostLikeSyncPayload {
  final int postId;
  final bool isLiked;
  final int likeCount;
  final PostLikeSyncOrigin origin;

  const PostLikeSyncPayload({
    required this.postId,
    required this.isLiked,
    required this.likeCount,
    required this.origin,
  });
}

class PostLikeSyncBus {
  PostLikeSyncBus._();

  static final PostLikeSyncBus instance = PostLikeSyncBus._();

  final StreamController<PostLikeSyncPayload> _controller =
      StreamController<PostLikeSyncPayload>.broadcast();

  Stream<PostLikeSyncPayload> get stream => _controller.stream;

  void emit(PostLikeSyncPayload payload) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(payload);
  }
}
