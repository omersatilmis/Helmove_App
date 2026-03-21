import 'dart:async';

class DeepLinkStore {
  DeepLinkStore._();

  static final DeepLinkStore instance = DeepLinkStore._();

  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();
  Uri? _pending;

  Stream<Uri> get stream => _controller.stream;

  void push(Uri uri) {
    _pending = uri;
    if (!_controller.isClosed) {
      _controller.add(uri);
    }
  }

  Uri? consume() {
    final uri = _pending;
    _pending = null;
    return uri;
  }

  void dispose() {
    _controller.close();
  }
}
