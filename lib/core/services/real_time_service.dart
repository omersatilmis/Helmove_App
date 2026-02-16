import 'dart:async';

import '../utils/app_logger.dart';
import 'app_session.dart';
import 'signalr_service.dart';

class RealTimeService {
  final AppSession _appSession;
  final SignalRService _signalRService;

  StreamSubscription<String?>? _tokenSubscription;
  String? _lastToken;
  bool _started = false;

  RealTimeService(this._appSession, this._signalRService);

  void start() {
    if (_started) return;
    _started = true;

    _tokenSubscription = _appSession.tokenStream.distinct().listen((token) async {
      await _syncSignalRWithToken(token);
    });

    unawaited(_syncSignalRWithToken(_appSession.token));
  }

  Future<void> _syncSignalRWithToken(String? token) async {
    final normalized = token?.trim();
    final hasToken = normalized != null && normalized.isNotEmpty;

    if (!hasToken) {
      _lastToken = null;
      await _signalRService.stop();
      return;
    }

    final tokenChanged = _lastToken != null && _lastToken != normalized;
    _lastToken = normalized;

    if (tokenChanged && _signalRService.isConnected) {
      AppLogger.info('RealTimeService: token changed, restarting SignalR connection.');
      await _signalRService.stop();
    }

    await _signalRService.init();
  }

  Future<void> stop() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _started = false;
    _lastToken = null;
    await _signalRService.stop();
  }
}
