import 'dart:async';

/// Blocks authenticated network traffic until startup token hydration finishes.
class AuthBootstrapGate {
  final Completer<void> _readyCompleter = Completer<void>();

  bool get isReady => _readyCompleter.isCompleted;

  Future<void> waitUntilReady() => _readyCompleter.future;

  void complete() {
    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
  }
}
