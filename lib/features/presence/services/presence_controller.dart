import 'dart:async';

import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/services/message_signalr_service.dart';
import '../../../core/utils/app_logger.dart';
import '../data/models/user_presence_model.dart';

/// Kullanıcı online/offline durumlarını yöneten merkezi controller.
///
/// Sorumlulukları:
///  - OnlineFriends event'iyle başlangıç state'ini doldurur.
///  - UserStatusChanged event'leriyle diff-update yapar.
///  - 30 saniyede bir SignalR üzerinden Heartbeat gönderir.
///  - Arka plana geçişte HTTP POST /api/presence/offline çağırır.
class PresenceController {
  final MessageSignalRService _signalRService;
  final Dio _dio;

  PresenceController({
    required MessageSignalRService signalRService,
    required Dio dio,
  })  : _signalRService = signalRService,
        _dio = dio;

  // ── State ──────────────────────────────────────────────────────────────────

  /// userId → UserPresenceModel haritası.
  final _presenceMap = BehaviorSubject<Map<int, UserPresenceModel>>.seeded({});

  Stream<Map<int, UserPresenceModel>> get presenceStream => _presenceMap.stream;
  Map<int, UserPresenceModel> get currentPresence => _presenceMap.value;

  /// Belirli bir kullanıcı için anlık durum.
  UserPresenceModel? presenceOf(int userId) => _presenceMap.value[userId];

  // ── Subscriptions & Timer ──────────────────────────────────────────────────

  StreamSubscription<List<int>>? _onlineFriendsSub;
  StreamSubscription<UserPresenceModel>? _userStatusChangedSub;
  Timer? _heartbeatTimer;

  static const _heartbeatInterval = Duration(seconds: 30);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Uygulama foreground'a geçince çağrılır.
  void onForeground() {
    _subscribeToPresenceEvents();
    _startHeartbeat();
    // Anlık olarak HTTP heartbeat gönder — 30s timer'ı bekleme.
    // Bu, POST /api/presence/offline sonrası sunucunun isOnline'ı false
    // bırakmasını engeller. Backend'in Heartbeat handler'ı isOnline=true
    // yazıyorsa SignalR heartbeat yeterli; yazılmıyorsa HTTP fallback kurtarır.
    unawaited(_sendOnlineSignal());
    AppLogger.info("PresenceController: foreground — online sinyali gönderildi");
  }

  /// Uygulama background'a geçince çağrılır.
  void onBackground() {
    _stopHeartbeat();
    _cancelSubscriptions();
    unawaited(_sendOfflineSignal());
    AppLogger.info("PresenceController: background — heartbeat durduruldu");
  }

  /// Servis ilk kez başlatılırken (uygulama ilk açılışı) çağrılır.
  void initialize() => onForeground();

  // ── Presence Event Handlers ────────────────────────────────────────────────

  void _subscribeToPresenceEvents() {
    // Zaten abone ise tekrar abone olma
    if (_onlineFriendsSub != null) return;

    _onlineFriendsSub =
        _signalRService.onOnlineFriends.listen(_handleOnlineFriends);

    _userStatusChangedSub =
        _signalRService.onUserStatusChanged.listen(_handleUserStatusChanged);
  }

  void _cancelSubscriptions() {
    _onlineFriendsSub?.cancel();
    _onlineFriendsSub = null;
    _userStatusChangedSub?.cancel();
    _userStatusChangedSub = null;
  }

  /// İlk bağlantıda gelen toplu liste — state'i sıfırdan oluşturur.
  void _handleOnlineFriends(List<int> onlineIds) {
    final current = Map<int, UserPresenceModel>.from(_presenceMap.value);

    // Önce mevcut herkesi offline yap, ardından listede olanları online işaretle
    for (final entry in current.entries) {
      current[entry.key] = entry.value.copyWith(isOnline: false);
    }
    for (final id in onlineIds) {
      current[id] = UserPresenceModel(userId: id, isOnline: true);
    }

    _presenceMap.add(current);
    AppLogger.info(
      "PresenceController: OnlineFriends işlendi — ${onlineIds.length} online",
    );
  }

  /// Tek kullanıcı değişimi — sadece ilgili kaydı günceller (diff update).
  void _handleUserStatusChanged(UserPresenceModel updated) {
    final current = Map<int, UserPresenceModel>.from(_presenceMap.value);
    current[updated.userId] = updated;
    _presenceMap.add(current);
    AppLogger.info(
      "PresenceController: UserStatusChanged userId=${updated.userId} "
      "online=${updated.isOnline}",
    );
  }

  // ── Heartbeat ──────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      await _signalRService.sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ── HTTP Presence Signals ──────────────────────────────────────────────────

  /// Foreground'a dönüşte anlık olarak online sinyali gönderir.
  /// Backend'in /api/presence/heartbeat endpoint'i isOnline=true yazmalı.
  Future<void> _sendOnlineSignal() async {
    try {
      await _dio.post('/api/presence/heartbeat');
      AppLogger.info("PresenceController: Online sinyali gönderildi (HTTP heartbeat)");
    } on DioException catch (e) {
      // Sessizce geç — SignalR heartbeat 30s içinde devreye girer
      AppLogger.warning(
        "PresenceController: Online sinyal hatası: ${e.message}",
      );
    }
  }

  Future<void> _sendOfflineSignal() async {
    try {
      await _dio.post('/api/presence/offline');
      AppLogger.info("PresenceController: Offline sinyali gönderildi");
    } on DioException catch (e) {
      AppLogger.warning(
        "PresenceController: Offline sinyal hatası (TTL devreye girer): ${e.message}",
      );
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _stopHeartbeat();
    _cancelSubscriptions();
    _presenceMap.close();
  }
}
