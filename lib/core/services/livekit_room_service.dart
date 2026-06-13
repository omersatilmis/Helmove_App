import 'dart:async';
import 'package:livekit_client/livekit_client.dart';

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
  /// [maxBitrate] — Sabit ses yayın bitrate'i (opsiyonel, default: 24 kbps).
  Future<void> connect(String url, String token, {int? maxBitrate}) async {
    // Önceki bağlantıyı temizle
    await disconnect();
    // Room oluştur
    _room = Room(
      roomOptions: RoomOptions(
        // Sadece ses — video yok
        defaultAudioPublishOptions: AudioPublishOptions(
          encoding: AudioEncoding(
            maxBitrate: maxBitrate ?? 24000,
          ),
          dtx: false,
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

      // İlk state güncelleme
      _emitParticipants();
      _emitMicState();
      _emitConnectionQualities();
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  /// Room'dan bağlantıyı kes.
  Future<void> disconnect() async {
    if (_room != null) {
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
  }

  /// Ses ayarlarını dinamik olarak güncelle (Gürültü engelleme vb.)
  Future<void> updateAudioSettings({required bool noiseSuppression}) async {
    if (_localParticipant == null) return;
    // LiveKit'te capture ayarlarını güncellemek için mikrofonu yeni seçeneklerle tekrar set ediyoruz.
    // Mevcut durumu koruyarak sadece ayarları değiştiriyoruz.
    final currentEnabled = _localParticipant!.isMicrophoneEnabled();
    await _localParticipant!.setMicrophoneEnabled(
      currentEnabled,
      audioCaptureOptions: AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: noiseSuppression,
        autoGainControl: noiseSuppression,
      ),
    );
  }

  /// Adaptif bitrate controller tarafından çağrılır.
  /// Aktif oturumda ses track'inin bitrate'ini dinamik olarak günceller.
  /// [bps] — hedef bitrate (örn: 16000, 32000).
  Future<void> updateBitrate(int bps) async {
    if (_localParticipant == null || _room == null) return;

    try {
      // Mevcut audio track'in publish options'ını güncelle
      for (final pub in _localParticipant!.audioTrackPublications) {
        final track = pub.track;
        if (track != null) {
          await _localParticipant!.publishAudioTrack(
            track,
            publishOptions: AudioPublishOptions(
              encoding: AudioEncoding(maxBitrate: bps),
              dtx: false,
            ),
          );
        }
      }
    } catch (e) {
      // Intentionally ignored.
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
    if (local != null) {
      qualities[local.identity] = local.connectionQuality;
    }

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
  }
}
