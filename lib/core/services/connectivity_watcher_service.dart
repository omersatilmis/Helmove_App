import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:rxdart/rxdart.dart';
import 'signalr_service.dart';
import 'livekit_room_service.dart';

enum ConnectionStatusType {
  online,
  disconnected,
  reconnecting,
  connecting,
  failed,
}

class ConnectionStatus {
  final ConnectionStatusType type;
  final String message;
  final int priority; // Higher is more urgent

  const ConnectionStatus({
    required this.type,
    required this.message,
    this.priority = 0,
  });

  static const none = ConnectionStatus(
    type: ConnectionStatusType.online,
    message: '',
    priority: -1,
  );
}

class ConnectivityWatcherService {
  final SignalRService _signalRService;
  final LiveKitRoomService _liveKitRoomService;

  final _statusController = BehaviorSubject<ConnectionStatus>.seeded(
    ConnectionStatus.none,
  );
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Network tipi stream'i (wifi/mobile/none) — Smart Reconnect için.
  final _networkTypeController = BehaviorSubject<String>.seeded('unknown');
  Stream<String> get networkTypeStream => _networkTypeController.stream;

  ConnectivityWatcherService(this._signalRService, this._liveKitRoomService) {
    _init();
  }

  bool _hasSignalRConnectedOnce = false;

  void _init() {
    CombineLatestStream.combine3(
      Connectivity().onConnectivityChanged,
      _signalRService.connectionStateStream,
      _liveKitRoomService.connectionStateStream.startWith(
        _liveKitRoomService.room?.connectionState ??
            ConnectionState.disconnected,
      ),
      (
        List<ConnectivityResult> net,
        HubConnectionState sig,
        ConnectionState lk,
      ) {
        return _calculateStatus(net, sig, lk);
      },
    ).listen((status) {
      _statusController.add(status);
    });

    // Network type stream: WiFi/Mobile/None changes
    Connectivity().onConnectivityChanged.listen((results) {
      final type = _mapNetworkType(results);
      if (type != _networkTypeController.value) {
        _networkTypeController.add(type);
      }
    });
  }

  /// ConnectivityResult listesini okunabilir tipe çevir.
  String _mapNetworkType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return 'wifi';
    if (results.contains(ConnectivityResult.mobile)) return 'mobile';
    if (results.contains(ConnectivityResult.ethernet)) return 'ethernet';
    if (results.contains(ConnectivityResult.none)) return 'none';
    return 'other';
  }

  ConnectionStatus _calculateStatus(
    List<ConnectivityResult> net,
    HubConnectionState sig,
    ConnectionState lk,
  ) {
    // 1. Internet Check (Highest Priority)
    final hasInternet =
        net.isNotEmpty && !net.contains(ConnectivityResult.none);
    if (!hasInternet) {
      return const ConnectionStatus(
        type: ConnectionStatusType.disconnected,
        message: 'İnternet bağlantısı kesildi',
        priority: 100,
      );
    }

    // 2. SignalR Check
    if (sig == HubConnectionState.Connected) {
      _hasSignalRConnectedOnce = true;
    }

    if (sig == HubConnectionState.Reconnecting) {
      return const ConnectionStatus(
        type: ConnectionStatusType.reconnecting,
        message: 'Sunucu bağlantısı yenileniyor...',
        priority: 80,
      );
    } else if (sig == HubConnectionState.Disconnected) {
      // Eğer daha önce hiç bağlanmadıysa, bu bir kopma değil "İlk Bağlantı" sürecidir.
      // Hata göstermek yerine "Bağlanıyor" veya boş durum dönebiliriz.
      if (!_hasSignalRConnectedOnce) {
        // İsterseniz burada 'Bağlanılıyor...' gibi bir durum da dönebilirsiniz
        // ancak kullanıcıyı rahatsız etmemek adına 'none' veya 'connecting' diyebiliriz.
        // Şimdilik sessiz kalması (none) en temizidir, veya connecting:
        return ConnectionStatus.none;
      }

      return const ConnectionStatus(
        type: ConnectionStatusType.disconnected,
        message: 'Sunucu bağlantısı koptu',
        priority: 70,
      );
    }

    // 3. LiveKit Check
    if (lk == ConnectionState.reconnecting) {
      return const ConnectionStatus(
        type: ConnectionStatusType.reconnecting,
        message: 'Ses motoru bağlanıyor...',
        priority: 60,
      );
    } else if (lk == ConnectionState.disconnected &&
        _liveKitRoomService.room != null) {
      // room null değil ama disconnected ise bağlantı kopmuş demektir
      return const ConnectionStatus(
        type: ConnectionStatusType.disconnected,
        message: 'Ses bağlantısı koptu',
        priority: 50,
      );
    }

    return ConnectionStatus.none;
  }

  void dispose() {
    _statusController.close();
    _networkTypeController.close();
  }
}
