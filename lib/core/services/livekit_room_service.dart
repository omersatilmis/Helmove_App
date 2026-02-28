import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:moto_comm_app_1/core/constants/audio_bitrate.dart';

/// LiveKit SFU room bağlantı yönetimi.
/// Ses iletişimi için room'a bağlanma, mikrofon kontrolü ve participant
/// event'lerini stream olarak sunar.
class LiveKitRoomService {
  Room? _room;
  LocalParticipant? _localParticipant;

  // --- STREAM CONTROLLERS ---
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final _participantsController =
      StreamController<List<RemoteParticipant>>.broadcast();
  final _activeSpeakersController =
      StreamController<List<Participant>>.broadcast();
  final _isMicEnabledController = StreamController<bool>.broadcast();
  final _qualityController =
      StreamController<Map<String, ConnectionQuality>>.broadcast();

  /// Room bağlantı durumu stream'i.
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Uzaktaki katılımcılar stream'i.
  Stream<List<RemoteParticipant>> get participantsStream =>
      _participantsController.stream;

  /// Aktif konuşmacılar stream'i.
  Stream<List<Participant>> get activeSpeakersStream =>
      _activeSpeakersController.stream;

  /// Mikrofon durumu stream'i.
  Stream<bool> get isMicEnabledStream => _isMicEnabledController.stream;

  /// Katılımcı bağlantı kalitesi stream'i (Identity -> Quality).
  Stream<Map<String, ConnectionQuality>> get qualityStream =>
      _qualityController.stream;

  /// Bağlı mı?
  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  /// Mevcut room.
  Room? get room => _room;

  // ============================================================
  // BAĞLANTI YÖNETİMİ
  // ============================================================

  /// LiveKit room'a bağlan.
  /// [url] — LiveKit sunucu WebSocket URL'i (backend'den gelir).
  /// [token] — JWT token (backend'den gelir).
  /// [maxBitrate] — Başlangıç ses yayın kalitesi (opsiyonel, default: medium).
  Future<void> connect(String url, String token, {int? maxBitrate}) async {
    // Önceki bağlantıyı temizle
    await disconnect();

    debugPrint('🎙️ [LiveKitRoomService] Connecting to $url');

    // Room oluştur
    _room = Room(
      roomOptions: RoomOptions(
        // Sadece ses — video yok
        defaultAudioPublishOptions: AudioPublishOptions(
          encoding: AudioEncoding(
            maxBitrate: maxBitrate ?? AudioBitrate.medium,
          ),
          dtx: true,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          videoEncoding: VideoEncoding(maxBitrate: 0, maxFramerate: 0),
        ),
        // Audio işleme
        defaultAudioCaptureOptions: AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      ),
    );

    // Room event listener
    _room!.addListener(_onRoomEvent);

    // Sunucuya bağlan
    try {
      await _room!.connect(
        url,
        token,
        fastConnectOptions: FastConnectOptions(
          microphone: const TrackOption(enabled: true),
          camera: const TrackOption(enabled: false),
          screen: const TrackOption(enabled: false),
        ),
      );

      _localParticipant = _room!.localParticipant;

      debugPrint(
        '✅ [LiveKitRoomService] Connected! Room: ${_room!.name}, '
        'Participants: ${_room!.remoteParticipants.length}',
      );

      // İlk state güncelleme
      _emitParticipants();
      _emitMicState();
      _emitConnectionQualities();
    } catch (e) {
      debugPrint('❌ [LiveKitRoomService] Connection failed: $e');
      await disconnect();
      rethrow;
    }
  }

  /// Room'dan bağlantıyı kes.
  Future<void> disconnect() async {
    if (_room != null) {
      debugPrint('👋 [LiveKitRoomService] Disconnecting from room');
      _room!.removeListener(_onRoomEvent);
      await _room!.disconnect();
      await _room!.dispose();
      _room = null;
      _localParticipant = null;
    }
  }

  // ============================================================
  // MİKROFON KONTROLÜ
  // ============================================================

  /// Mikrofonu aç/kapat.
  Future<void> toggleMicrophone() async {
    if (_localParticipant == null) return;

    final enabled = _localParticipant!.isMicrophoneEnabled();
    await _localParticipant!.setMicrophoneEnabled(!enabled);
    _emitMicState();

    debugPrint('🎤 [LiveKitRoomService] Mic ${!enabled ? "ON" : "OFF"}');
  }

  /// Mikrofonu belirli bir duruma ayarla.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_localParticipant == null) return;
    await _localParticipant!.setMicrophoneEnabled(enabled);
    _emitMicState();
  }

  /// [NEW] Tüm uzak katılımcıların sesini aç/kapat (Playback Mute).
  /// Overlap sırasında yankıyı önlemek için kullanılır.
  void setIncomingAudioEnabled(bool enabled) {
    if (_room == null) return;

    for (final participant in _room!.remoteParticipants.values) {
      for (final publication in participant.audioTrackPublications) {
        // Track'i mute/unmute et (Subscription'ı kapatmak yerine sesi kısıyoruz/kapatıyoruz)
        publication.track?.mediaStreamTrack.enabled = enabled;
      }
    }
    debugPrint(
      '🔇 [LiveKitRoomService] Incoming Audio \u2192 ${enabled ? "UNMUTED" : "MUTED"}',
    );
  }

  /// Ses ayarlarını dinamik olarak güncelle (Gürültü engelleme vb.)
  Future<void> updateAudioSettings({required bool noiseSuppression}) async {
    if (_localParticipant == null) return;

    debugPrint(
      '🎙️ [LiveKitRoomService] Updating audio settings: noiseSuppression=$noiseSuppression',
    );

    // LiveKit'te capture ayarlarını güncellemek için mikrofonu yeni seçeneklerle tekrar set ediyoruz.
    // Mevcut durumu koruyarak sadece ayarları değiştiriyoruz.
    final currentEnabled = _localParticipant!.isMicrophoneEnabled();
    await _localParticipant!.setMicrophoneEnabled(
      currentEnabled,
      audioCaptureOptions: AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: noiseSuppression,
        autoGainControl: true,
      ),
    );
  }

  /// Adaptif bitrate controller tarafından çağrılır.
  /// Aktif oturumda ses track'inin bitrate'ini dinamik olarak günceller.
  /// [bps] — hedef bitrate (örn: 16000, 32000).
  Future<void> updateBitrate(int bps) async {
    if (_localParticipant == null || _room == null) return;

    debugPrint('🎙️ [LiveKitRoomService] Updating bitrate -> $bps bps');

    try {
      // Mevcut audio track'in publish options'ını güncelle
      for (final pub in _localParticipant!.audioTrackPublications) {
        final track = pub.track;
        if (track != null) {
          await _localParticipant!.publishAudioTrack(
            track,
            publishOptions: AudioPublishOptions(
              encoding: AudioEncoding(maxBitrate: bps),
              dtx: true,
            ),
          );
          debugPrint(
            '🎙️ [LiveKitRoomService] Audio track bitrate updated -> $bps bps',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [LiveKitRoomService] updateBitrate failed: $e');
    }
  }

  /// Mikrofon şu an açık mı?
  bool get isMicrophoneEnabled =>
      _localParticipant?.isMicrophoneEnabled() ?? false;

  // ============================================================
  // KATILIMCI BİLGİLERİ
  // ============================================================

  /// Tüm uzak katılımcıların anlık listesi.
  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? [];

  /// Toplam katılımcı sayısı (yerel + uzak).
  int get participantCount =>
      (_room?.remoteParticipants.length ?? 0) + (_room != null ? 1 : 0);

  // ============================================================
  // INTERNAL EVENT HANDLING
  // ============================================================

  void _onRoomEvent() {
    if (_room == null) return;

    // Bağlantı durumu
    _connectionStateController.add(_room!.connectionState);

    // Katılımcı değişimi
    _emitParticipants();

    // Aktif konuşmacılar
    _activeSpeakersController.add(_room!.activeSpeakers);

    // Bağlantı kaliteleri
    _emitConnectionQualities();
  }

  void _emitParticipants() {
    if (_room == null) return;
    _participantsController.add(_room!.remoteParticipants.values.toList());
  }

  void _emitMicState() {
    _isMicEnabledController.add(isMicrophoneEnabled);
  }

  void _emitConnectionQualities() {
    final room = _room;
    if (room == null) return;

    final qualities = <String, ConnectionQuality>{};

    for (final participant in room.remoteParticipants.values) {
      qualities[participant.identity] = participant.connectionQuality;
    }

    final local = room.localParticipant;
    qualities[local.identity] = local.connectionQuality;

    _qualityController.add(qualities);
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Tüm kaynakları serbest bırak.
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _participantsController.close();
    await _activeSpeakersController.close();
    await _isMicEnabledController.close();
    await _qualityController.close();
    debugPrint('🧹 [LiveKitRoomService] Disposed');
  }
}
