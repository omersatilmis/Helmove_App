import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/signalr_service.dart';
import '../../../../core/services/models/signalr_payloads.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/repositories/group_ride_repository.dart';
import 'live_rider.dart';

/// Grup sürüşünde canlı konum paylaşımı + ortak rota beyni.
///
/// Singleton (DI). Bir grup sürüşüne girilince [start] ile aktifleşir; SignalR
/// canlı konum/rota event'lerini dinler, kendi GPS konumunu (paylaşım açıksa)
/// gruba yayınlar. Harita (map_page) bunu [ChangeNotifier] olarak dinleyip
/// diğer sürücüleri ve ortak rotayı çizer.
class LiveRideController extends ChangeNotifier {
  final SignalRService _signalR;
  final AuthLocalDataSource _authLocalDataSource;
  final GroupRideRepository _groupRideRepository;

  LiveRideController(
    this._signalR,
    this._authLocalDataSource,
    this._groupRideRepository,
  );

  // ── State ──────────────────────────────────────────────────────────────────
  int? _activeRideId;
  int? _myUserId;
  bool _isSharingLocation = true;
  bool _isOrganizer = false;

  /// Konumu bilinen sürücüler (haritada çizilenler). Kendisi hariç.
  final Map<int, LiveRider> _riders = {};

  /// userId → profil (isim/foto/organizatör). Konumdan bağımsız tutulur ki
  /// konum güncellemesi geldiğinde isim/foto kaybolmasın.
  final Map<int, _RiderProfile> _profiles = {};

  RideRoutePayload? _sharedRoute;

  // ── Subscriptions ───────────────────────────────────────────────────────────
  StreamSubscription? _snapshotSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _joinedSub;
  StreamSubscription? _leftSub;
  StreamSubscription? _stoppedSub;
  StreamSubscription? _routeSub;
  StreamSubscription<Position>? _gpsSub;
  DateTime? _lastSentAt;

  /// İki konum yayını arası minimum süre (server-side throttle ile uyumlu).
  static const Duration _minSendInterval = Duration(seconds: 3);
  static const int _gpsDistanceFilterMeters = 12;

  // ── Public getters ───────────────────────────────────────────────────────────
  bool get isActive => _activeRideId != null;
  int? get activeRideId => _activeRideId;
  bool get isSharingLocation => _isSharingLocation;
  bool get isOrganizer => _isOrganizer;
  List<LiveRider> get riders => _riders.values.toList(growable: false);
  RideRoutePayload? get sharedRoute => _sharedRoute;
  bool get hasSharedRoute => _sharedRoute?.hasGeometry ?? false;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Bir grup sürüşüne girilince çağrılır. Aynı sürüş için tekrar çağrı no-op.
  /// [organizerId] verilirse, mevcut kullanıcı organizatör mü buradan belirlenir
  /// (snapshot ayrıca doğrular/günceller).
  Future<void> start(int rideId, {int? organizerId}) async {
    if (rideId <= 0) return;

    final myUserId = await _authLocalDataSource.getUserId();
    final amOrganizer = organizerId != null && myUserId == organizerId;

    if (_activeRideId == rideId) {
      if (amOrganizer && !_isOrganizer) {
        _isOrganizer = true;
        notifyListeners();
      }
      return;
    }

    await _teardown();

    _activeRideId = rideId;
    _isSharingLocation = true;
    _isOrganizer = amOrganizer;
    _myUserId = myUserId;

    _subscribeStreams();

    // JoinRideGroup → backend RideJoinSnapshot ile rota + mevcut konumları yollar.
    await _signalR.joinRideGroup(rideId.toString());

    await _startGpsBroadcast();
    notifyListeners();
    AppLogger.info("LiveRide: started ride=$rideId organizer=$_isOrganizer");
  }

  /// Sürüşten çıkış / sürüş bitti. Yerel durumu temizler. (SignalR ride grubu
  /// üyeliği GroupRideBloc tarafından yönetilir; burada yalnızca canlı katman.)
  Future<void> stop() async {
    if (_activeRideId == null) return;
    AppLogger.info("LiveRide: stopped ride=$_activeRideId");
    await _teardown();
    notifyListeners();
  }

  Future<void> _teardown() async {
    await _snapshotSub?.cancel();
    await _locationSub?.cancel();
    await _joinedSub?.cancel();
    await _leftSub?.cancel();
    await _stoppedSub?.cancel();
    await _routeSub?.cancel();
    await _gpsSub?.cancel();
    _snapshotSub = null;
    _locationSub = null;
    _joinedSub = null;
    _leftSub = null;
    _stoppedSub = null;
    _routeSub = null;
    _gpsSub = null;
    _lastSentAt = null;
    _activeRideId = null;
    _myUserId = null;
    _isOrganizer = false;
    _riders.clear();
    _profiles.clear();
    _sharedRoute = null;
  }

  // ── Sharing toggle ───────────────────────────────────────────────────────────

  Future<void> setSharing(bool share) async {
    final rideId = _activeRideId;
    if (rideId == null) return;
    if (_isSharingLocation == share) return;
    _isSharingLocation = share;
    notifyListeners();

    await _signalR.setRideLocationSharing(rideId.toString(), share);

    if (share) {
      await _startGpsBroadcast();
    } else {
      await _gpsSub?.cancel();
      _gpsSub = null;
    }
  }

  // ── Route publish (organizatör) ──────────────────────────────────────────────

  /// Organizatörün rotasını backend'e kaydeder; backend tüm üyelere
  /// `RideRouteUpdated` yayar. [geometry] encoded polyline6 (PolylineCodec).
  Future<bool> publishRoute({
    required String geometry,
    String? profile,
    double? distanceMeters,
    int? durationSeconds,
  }) async {
    final rideId = _activeRideId;
    if (rideId == null) return false;

    final detail = await _groupRideRepository.getGroupRideById(rideId);
    return detail.fold((failure) {
      AppLogger.error("LiveRide: publishRoute fetch failed ${failure.message}");
      return false;
    }, (ride) async {
      final updated = ride.copyWith(
        routeGeometry: geometry,
        routeProfile: profile ?? 'driving',
        routeDistanceMeters: distanceMeters,
        routeDurationSeconds: durationSeconds,
      );
      final result = await _groupRideRepository.updateGroupRide(
        rideId,
        updated,
      );
      return result.fold(
        (failure) {
          AppLogger.error("LiveRide: publishRoute failed ${failure.message}");
          return false;
        },
        (_) {
          // Anlık geri bildirim için lokal de güncelle (broadcast da gelecek).
          _sharedRoute = RideRoutePayload(
            geometry: geometry,
            profile: profile ?? 'driving',
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
          );
          notifyListeners();
          AppLogger.info("LiveRide: route published ride=$rideId");
          return true;
        },
      );
    });
  }

  // ── SignalR streams ──────────────────────────────────────────────────────────

  void _subscribeStreams() {
    _snapshotSub = _signalR.rideJoinSnapshotStream.listen(_onSnapshot);
    _locationSub = _signalR.rideLocationUpdateStream.listen(_onLocationUpdate);
    _joinedSub = _signalR.rideParticipantJoinedStream.listen(_onParticipantJoined);
    _leftSub = _signalR.rideParticipantLeftStream.listen(_onParticipantLeft);
    _stoppedSub = _signalR.rideParticipantLocationStoppedStream.listen(
      _onParticipantLocationStopped,
    );
    _routeSub = _signalR.rideRouteUpdatedStream.listen(_onRouteUpdated);
  }

  void _onSnapshot(RideJoinSnapshotPayload payload) {
    if (payload.rideId != _activeRideId) return;

    _riders.clear();
    _profiles.clear();

    for (final p in payload.participants) {
      _profiles[p.userId] = _RiderProfile(
        fullName: p.fullName,
        username: p.username,
        profilePictureUrl: p.profilePictureUrl,
        isOrganizer: p.isOrganizer,
      );
      if (p.userId == _myUserId) {
        if (p.isOrganizer) _isOrganizer = true;
        continue;
      }
      if (p.shareLocation && p.lat != null && p.lng != null) {
        _riders[p.userId] = LiveRider(
          userId: p.userId,
          fullName: p.fullName,
          username: p.username,
          profilePictureUrl: p.profilePictureUrl,
          lat: p.lat!,
          lng: p.lng!,
          heading: p.heading,
          speedKmh: p.speedKmh,
          isOrganizer: p.isOrganizer,
          updatedAt: p.lastLocationAt ?? DateTime.now(),
        );
      }
    }

    if (payload.route != null && payload.route!.hasGeometry) {
      _sharedRoute = payload.route;
    }
    notifyListeners();
  }

  void _onLocationUpdate(Map<String, dynamic> raw) {
    if (_activeRideId == null) return;
    final payload = RideLocationUpdatePayload.tryParse(raw);
    if (payload == null) return;
    if (payload.userId == _myUserId) return;

    final profile = _profiles[payload.userId];
    final existing = _riders[payload.userId];
    if (existing != null) {
      _riders[payload.userId] = existing.withLocation(
        lat: payload.lat,
        lng: payload.lng,
        heading: payload.heading,
        speedKmh: payload.speedKmh,
        updatedAt: payload.timestamp ?? DateTime.now(),
      );
    } else {
      _riders[payload.userId] = LiveRider(
        userId: payload.userId,
        fullName: profile?.fullName,
        username: profile?.username,
        profilePictureUrl: profile?.profilePictureUrl,
        lat: payload.lat,
        lng: payload.lng,
        heading: payload.heading,
        speedKmh: payload.speedKmh,
        isOrganizer: profile?.isOrganizer ?? false,
        updatedAt: payload.timestamp ?? DateTime.now(),
      );
    }
    notifyListeners();
  }

  void _onParticipantJoined(RideParticipantEventPayload payload) {
    if (_activeRideId != null && payload.rideId != 0 &&
        payload.rideId != _activeRideId) {
      return;
    }
    if (payload.userId == _myUserId) return;
    _profiles[payload.userId] = _RiderProfile(
      fullName: payload.fullName,
      username: payload.username,
      profilePictureUrl: payload.profilePictureUrl,
      isOrganizer: _profiles[payload.userId]?.isOrganizer ?? false,
    );
    final existing = _riders[payload.userId];
    if (existing != null) {
      _riders[payload.userId] = existing.withProfile(
        fullName: payload.fullName,
        username: payload.username,
        profilePictureUrl: payload.profilePictureUrl,
      );
      notifyListeners();
    }
  }

  void _onParticipantLeft(RideParticipantEventPayload payload) {
    if (_activeRideId != null && payload.rideId != 0 &&
        payload.rideId != _activeRideId) {
      return;
    }
    final removed = _riders.remove(payload.userId) != null;
    _profiles.remove(payload.userId);
    if (removed) notifyListeners();
  }

  void _onParticipantLocationStopped(RideParticipantEventPayload payload) {
    if (_activeRideId != null && payload.rideId != 0 &&
        payload.rideId != _activeRideId) {
      return;
    }
    // Konum paylaşımını kapattı → haritadan kaldır, profili koru.
    final removed = _riders.remove(payload.userId) != null;
    if (removed) notifyListeners();
  }

  void _onRouteUpdated(RideRoutePayload payload) {
    if (!payload.hasGeometry) return;
    _sharedRoute = payload;
    notifyListeners();
  }

  // ── GPS broadcast ─────────────────────────────────────────────────────────────

  Future<void> _startGpsBroadcast() async {
    if (!_isSharingLocation) return;
    await _gpsSub?.cancel();
    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _gpsDistanceFilterMeters,
      );
      _gpsSub = Geolocator.getPositionStream(locationSettings: settings).listen(
        _onGpsPosition,
        onError: (_) {},
      );
    } catch (e) {
      AppLogger.warning("LiveRide: GPS stream başlatılamadı: $e");
    }
  }

  void _onGpsPosition(Position position) {
    final rideId = _activeRideId;
    if (rideId == null || !_isSharingLocation) return;

    final now = DateTime.now();
    if (_lastSentAt != null && now.difference(_lastSentAt!) < _minSendInterval) {
      return;
    }
    _lastSentAt = now;

    final speedKmh = position.speed.isFinite && position.speed >= 0
        ? position.speed * 3.6
        : null;
    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : null;

    _signalR.updateRideLocation(
      rideId.toString(),
      position.latitude,
      position.longitude,
      heading: heading,
      speedKmh: speedKmh,
    );
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }
}

class _RiderProfile {
  final String? fullName;
  final String? username;
  final String? profilePictureUrl;
  final bool isOrganizer;
  const _RiderProfile({
    this.fullName,
    this.username,
    this.profilePictureUrl,
    this.isOrganizer = false,
  });
}
