import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:moto_comm_app_1/core/constants/audio_bitrate.dart';
import '../utils/app_logger.dart';

/// P2P (Mode A) 1v1 arama iÃ§in WebRTC motoru.
///
/// Bu servis UI'dan tamamen baÄŸÄ±msÄ±zdÄ±r. Sadece ÅŸunlarÄ± yapar:
/// - RTCPeerConnection oluÅŸturma (TURN credential'larÄ± ile)
/// - SDP Offer/Answer Ã¼retme ve uzak SDP'yi set etme
/// - ICE Candidate ekleme
/// - Mikrofon (LocalStream) yÃ¶netimi
/// - Gelen ses (RemoteStream) yÃ¶netimi
/// - BaÄŸlantÄ± durumu takibi (Stream olarak dÄ±ÅŸarÄ±ya verir)
///
/// KullanÄ±m akÄ±ÅŸÄ±:
/// 1. initialize(iceServers) ile PeerConnection oluÅŸtur
/// 2. startLocalStream() ile mikrofonu aÃ§
/// 3. createOffer() veya createAnswer() ile SDP Ã¼ret
/// 4. setRemoteDescription() ile karÅŸÄ± tarafÄ±n SDP'sini set et
/// 5. addIceCandidate() ile ICE candidate'leri ekle
/// 6. dispose() ile temizlik yap
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _pendingCandidates = [];
  int _currentBitrate = AudioBitrate.medium; // Varsayılan: Medium

  // ============================================================
  // STREAMS â€” UI KatmanÄ±na veri aktarÄ±mÄ±
  // ============================================================

  /// Gelen uzak ses stream'i deÄŸiÅŸtiÄŸinde tetiklenir
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get remoteStream$ => _remoteStreamController.stream;

  /// Yerel mikrofon stream'i deÄŸiÅŸtiÄŸinde tetiklenir
  final _localStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get localStream$ => _localStreamController.stream;

  /// ICE candidate Ã¼retildiÄŸinde tetiklenir (SignalR ile karÅŸÄ± tarafa gÃ¶nderilmeli)
  final _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();
  Stream<RTCIceCandidate> get onIceCandidate$ => _iceCandidateController.stream;

  /// PeerConnection durumu deÄŸiÅŸtiÄŸinde tetiklenir
  final _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get connectionState$ =>
      _connectionStateController.stream;

  /// ICE toplama tamamlanÄ±nca tetiklenir
  final _iceGatheringStateController =
      StreamController<RTCIceGatheringState>.broadcast();
  Stream<RTCIceGatheringState> get iceGatheringState$ =>
      _iceGatheringStateController.stream;

  // [NEW] Connection Quality Stream
  final _connectionQualityController = StreamController<String>.broadcast();
  Stream<String> get connectionQualityStream =>
      _connectionQualityController.stream;
  Timer? _statsTimer;
  int _poorQualityCount = 0;

  // ============================================================
  // GETTERS
  // ============================================================

  /// PeerConnection aktif mi?
  bool get isConnected =>
      _peerConnection?.connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  /// PeerConnection oluÅŸturuldu mu?
  bool get isInitialized => _peerConnection != null;

  /// Mikrofon aÃ§Ä±k mÄ±?
  bool get isMicrophoneOn => _localStream != null && _isMicEnabled;

  /// Yerel stream referansÄ± (UI gerekirse)
  MediaStream? get localStream => _localStream;

  /// Uzak stream referansÄ± (UI gerekirse)
  MediaStream? get remoteStream => _remoteStream;

  bool _isMicEnabled = true;
  bool _noiseSuppressionEnabled = true;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// PeerConnection'Ä± TURN/STUN sunucu bilgileriyle oluÅŸturur.
  ///
  /// [iceServers] Backend'den gelen sunucu listesi. Ã–rnek:
  /// ```dart
  /// [
  ///   {'urls': ['stun:stun.l.google.com:19302']},
  ///   {'urls': ['turn:host:443'], 'username': 'x', 'credential': 'y'},
  /// ]
  /// ```
  Future<void> initialize(List<Map<String, dynamic>> iceServers) async {
    if (_peerConnection != null) {
      AppLogger.warning(
        'WebRTC: initialize ignored, PeerConnection already initialized.',
      );
      return;
    }

    _pendingCandidates.clear();

    AppLogger.info('WebRTC: PeerConnection baÅŸlatÄ±lÄ±yor...');
    final sanitizedIceServers = _sanitizeIceServers(iceServers);
    AppLogger.info(
      'WebRTC: ICE server sanitize sonrasÄ± count=${sanitizedIceServers.length}',
    );

    final configuration = <String, dynamic>{
      'iceServers': sanitizedIceServers,
      // P2P Ã¶ncelikli, TURN gerektiÄŸinde kullanÄ±lÄ±r
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'sdpSemantics': 'unified-plan',
      'iceCandidatePoolSize': 2, // Bağlantı öncesi aday toplamayı hızlandırır
    };

    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _peerConnection = await createPeerConnection(configuration, constraints);
    _registerPeerConnectionCallbacks();

    // İYİLEŞTİRME: Varsayılan olarak sesi hoparlöre (Speaker) yönlendir.
    // Motosiklet interkom deneyimi için hoparlör kullanımı şarttır.
    await Helper.setSpeakerphoneOn(true);

    AppLogger.info('WebRTC: PeerConnection oluÅŸturuldu.');
  }

  List<Map<String, dynamic>> _sanitizeIceServers(
    List<Map<String, dynamic>> servers,
  ) {
    final normalized = <Map<String, dynamic>>[];

    for (final server in servers) {
      final rawUrls = server['urls'] ?? server['url'];
      final urls = <String>[];

      if (rawUrls is String && rawUrls.trim().isNotEmpty) {
        urls.add(rawUrls.trim());
      } else if (rawUrls is List) {
        urls.addAll(
          rawUrls
              .map((u) => u?.toString().trim() ?? '')
              .where((u) => u.isNotEmpty),
        );
      }

      if (urls.isEmpty) {
        continue;
      }

      final hasTurn = urls.any(
        (u) => u.startsWith('turn:') || u.startsWith('turns:'),
      );
      final username = server['username']?.toString().trim();
      final credential = server['credential']?.toString().trim();

      if (hasTurn &&
          (username == null ||
              username.isEmpty ||
              credential == null ||
              credential.isEmpty)) {
        AppLogger.warning(
          'WebRTC: Invalid TURN entry filtered (username/credential missing): $urls',
        );
        continue;
      }

      final item = <String, dynamic>{'urls': urls};
      if (username != null && username.isNotEmpty) {
        item['username'] = username;
      }
      if (credential != null && credential.isNotEmpty) {
        item['credential'] = credential;
      }
      normalized.add(item);
    }

    if (normalized.isEmpty) {
      return [
        {
          'urls': ['stun:stun.l.google.com:19302'],
        },
      ];
    }
    return normalized;
  }

  /// PeerConnection callback'lerini kaydeder
  void _registerPeerConnectionCallbacks() {
    final pc = _peerConnection;
    if (pc == null) return;

    // Start Stats Polling
    _startStatsTimer();

    // ICE Candidate Ã¼retildiÄŸinde â†’ SignalR ile karÅŸÄ± tarafa gÃ¶nderilecek
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      AppLogger.info(
        'WebRTC: ICE Candidate Ã¼retildi: ${candidate.candidate?.substring(0, 50)}...',
      );
      _iceCandidateController.add(candidate);
    };

    // Uzak stream eklendiÄŸinde (karÅŸÄ± tarafÄ±n sesi geldiÄŸinde)
    pc.onTrack = (RTCTrackEvent event) {
      AppLogger.info(
        'WebRTC: Remote track alÄ±ndÄ±. Kind: ${event.track.kind}',
      );
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream);
      }
    };

    // BaÄŸlantÄ± durumu deÄŸiÅŸiklikleri
    pc.onConnectionState = (RTCPeerConnectionState state) {
      AppLogger.info('WebRTC: ConnectionState â†’ $state');
      _connectionStateController.add(state);

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        AppLogger.warning('WebRTC: BaÄŸlantÄ± koptu veya baÅŸarÄ±sÄ±z oldu.');
      }
    };

    // ICE toplama durumu
    pc.onIceGatheringState = (RTCIceGatheringState state) {
      AppLogger.info('WebRTC: ICE Gathering â†’ $state');
      _iceGatheringStateController.add(state);
    };

    // Uzak stream kaldÄ±rÄ±ldÄ±ÄŸÄ±nda
    pc.onRemoveStream = (MediaStream stream) {
      AppLogger.info('WebRTC: Remote stream kaldÄ±rÄ±ldÄ±.');
      _remoteStream = null;
      _remoteStreamController.add(null);
    };
  }

  // ============================================================
  // LOCAL STREAM â€” Mikrofon YÃ¶netimi
  // ============================================================

  /// Mikrofonu aÃ§ar ve PeerConnection'a ekler.
  /// PeerConnection initialize edildikten sonra Ã§aÄŸrÄ±lmalÄ±.
  Future<void> startLocalStream() async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError(
        'WebRTC: startLocalStream called before PeerConnection initialize',
      );
    }
    if (_localStream != null) {
      AppLogger.warning(
        'WebRTC: startLocalStream ignored, local stream already started.',
      );
      return;
    }

    AppLogger.info('WebRTC: Mikrofon aÃ§Ä±lÄ±yor...');

    final constraints = <String, dynamic>{
      'audio': {
        // Düşük gecikme ve donanım hızlandırma için özel ayarlar
        'echoCancellation': true, // Yankı giderme
        'googEchoCancellation': true,
        'googEchoCancellation2': true,
        'googDAEchoCancellation': true, // Donanım tabanlı AEC
        'noiseSuppression': _noiseSuppressionEnabled, // Gürültü engelleme
        'googNoiseSuppression':
            _noiseSuppressionEnabled, // Google gürültü bastırma
        'googNoiseReduction':
            _noiseSuppressionEnabled, // Ekstra gürültü azaltma
        'autoGainControl': true, // Otomatik ses seviyesi
        'googAutoGainControl': true,
        'googHighpassFilter': true,
        'googAudioMirroring': false,
      },
      'video': false, // Sadece ses â€” video yok
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    _isMicEnabled = true;

    // Track'leri PeerConnection'a ekle
    final audioTrack = _localStream!.getAudioTracks().first;
    await pc.addTrack(audioTrack, _localStream!);

    _localStreamController.add(_localStream);
    AppLogger.info('WebRTC: Mikrofon aÃ§Ä±ldÄ± ve PeerConnection\'a eklendi.');
  }

  /// Mikrofonu aÃ§ar/kapatÄ±r (toggle). Track'i tamamen kaldÄ±rmaz, sadece mute eder.
  void toggleMicrophone() {
    if (_localStream == null) return;

    _isMicEnabled = !_isMicEnabled;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = _isMicEnabled;
    }

    AppLogger.info(
      'WebRTC: Mikrofon ${_isMicEnabled ? "aÃ§Ä±ldÄ±" : "kapatÄ±ldÄ±"}',
    );
  }

  /// Mikrofonu belirli bir duruma set eder
  /// Mikrofonu belirli bir duruma set eder
  void setMicrophoneEnabled(bool enabled) {
    if (_localStream == null) return;

    _isMicEnabled = enabled;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = enabled;
    }

    AppLogger.info(
      'WebRTC: Mikrofon \u2192 ${enabled ? "a\u00e7\u0131k" : "kapal\u0131"}',
    );
  }

  /// Uzak sesi (gelen sesi) aç/kapat (Playback Mute)
  /// Overlap sırasında yankıyı önlemek için kullanılır.
  void setRemoteAudioEnabled(bool enabled) {
    if (_remoteStream == null) return;

    for (final track in _remoteStream!.getAudioTracks()) {
      track.enabled = enabled;
    }
    AppLogger.info(
      'WebRTC: Remote Audio \u2192 ${enabled ? "UNMUTED" : "MUTED"}',
    );
  }

  /// Hoparlör / Ahize geçişi (UI'dan çağrılabilir)
  Future<void> setSpeakerphone(bool enable) async {
    await Helper.setSpeakerphoneOn(enable);
    AppLogger.info('WebRTC: Ses çıkışı -> ${enable ? "Hoparlör" : "Ahize"}');
  }

  /// Ses ayarlarını dinamik olarak güncelle (Gürültü engelleme vb.)
  Future<void> updateAudioSettings({required bool noiseSuppression}) async {
    _noiseSuppressionEnabled = noiseSuppression;

    if (_localStream == null || _peerConnection == null) return;

    AppLogger.info(
      'WebRTC: Ses ayarları güncelleniyor: noiseSuppression=$noiseSuppression',
    );

    // Mevcut stream'i ve track'leri temizleyip yeni ayarlarla yeniden başlatıyoruz.
    // "Motoru yeniden başlatmak" mantığına en uygun ve stabil yöntem budur.
    final wasMicEnabled = _isMicEnabled;

    try {
      // 1. Mevcut track'leri durdur
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      _localStream = null;

      // 2. Yeni stream'i başlat (Yeni constraints ile)
      await startLocalStream();

      // 3. Mikrofon durumunu koru
      setMicrophoneEnabled(wasMicEnabled);

      AppLogger.info('WebRTC: Ses ayarları başarıyla uygulandı.');
    } catch (e) {
      AppLogger.error('WebRTC: Ses ayarları güncellenirken hata oluştu', e);
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // KALDIRILDI: setAudioQuality(CallAudioQuality) ve CallAudioQuality enum
  // Bitrate yönetimi artık tek noktadan: AdaptiveBitrateController
  // üzerinden yapılıyor. Tavan (ceiling) değişiklikleri:
  //   Settings → IntercomEngine.onAudioSettingsChanged()
  //     → AdaptiveBitrateController.updateCeilingFromKey()
  //       → bitrate$ → WebRTCService.setBitrate() / LiveKit.updateBitrate()
  // ──────────────────────────────────────────────────────────────────

  /// Adaptif bitrate controller tarafından çağrılır.
  /// Mevcut bağlantıda bitrate'i değiştirmek için SDP renegotiation yapar.
  /// [bps] — hedef bitrate (örn: 16000, 32000, 48000).
  Future<void> setBitrate(int bps) async {
    _currentBitrate = bps;
    AppLogger.info('WebRTC: Adaptive bitrate -> $bps bps');

    // Aktif bağlantı varsa SDP renegotiation yap
    final pc = _peerConnection;
    if (pc == null) return;

    try {
      // Sender üzerinden maxBitrate ayarla (SDP renegotiation yerine daha hafif)
      final senders = await pc.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'audio') {
          final params = sender.parameters;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            params.encodings![0].maxBitrate = bps;
            await sender.setParameters(params);
            AppLogger.info('WebRTC: Sender bitrate updated -> $bps bps');
          }
        }
      }
    } catch (e) {
      AppLogger.error('WebRTC: setBitrate failed', e);
    }
  }

  /// Ağ değişiminde (WiFi → 4G) ICE bağlantısını yeniden başlatır.
  /// Mevcut oturumu bozmadan yeni ICE candidate'ler üretir.
  Future<RTCSessionDescription?> restartIce() async {
    final pc = _peerConnection;
    if (pc == null) {
      AppLogger.warning('WebRTC: restartIce called but no peer connection');
      return null;
    }

    AppLogger.info('WebRTC: ICE Restart başlatılıyor...');

    try {
      final offerConstraints = <String, dynamic>{
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': false,
          'IceRestart': true,
        },
      };

      final offer = await pc.createOffer(offerConstraints);
      final optimizedSdp = _optimizeSdp(offer.sdp!);
      final optimizedOffer = RTCSessionDescription(optimizedSdp, offer.type);

      await pc.setLocalDescription(optimizedOffer);
      AppLogger.info('WebRTC: ICE Restart offer oluşturuldu');
      return optimizedOffer;
    } catch (e) {
      AppLogger.error('WebRTC: ICE Restart failed', e);
      return null;
    }
  }

  // ============================================================
  // SDP â€” Offer / Answer
  // ============================================================

  /// SDP Offer oluÅŸturur (arayan taraf Ã§aÄŸÄ±rÄ±r).
  /// DÃ¶nen RTCSessionDescription, SignalR SendOffer ile karÅŸÄ± tarafa gÃ¶nderilir.
  Future<RTCSessionDescription> createOffer() async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('WebRTC: createOffer called before initialize');
    }

    AppLogger.info('WebRTC: SDP Offer oluÅŸturuluyor...');

    final offerConstraints = <String, dynamic>{
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
    };

    final offer = await pc.createOffer(offerConstraints);
    if (offer.sdp == null ||
        offer.sdp!.trim().isEmpty ||
        offer.type == null ||
        offer.type!.trim().isEmpty) {
      throw StateError('WebRTC: createOffer returned invalid description');
    }

    // SDP Munging: Opus codec ayarlarını optimize et (Düşük gecikme için)
    final optimizedSdp = _optimizeSdp(offer.sdp!);
    final optimizedOffer = RTCSessionDescription(optimizedSdp, offer.type);

    await pc.setLocalDescription(optimizedOffer);
    AppLogger.info('WebRTC: SDP Offer length=${offer.sdp?.length ?? 0}');

    AppLogger.info(
      'WebRTC: SDP Offer oluşturuldu (Optimize edildi) ve LocalDescription set edildi.',
    );
    return optimizedOffer;
  }

  /// SDP Answer oluÅŸturur (aranan taraf Ã§aÄŸÄ±rÄ±r).
  /// Remote Offer setRemoteDescription ile set edildikten sonra Ã§aÄŸrÄ±lmalÄ±.
  /// DÃ¶nen RTCSessionDescription, SignalR SendAnswer ile karÅŸÄ± tarafa gÃ¶nderilir.
  Future<RTCSessionDescription> createAnswer() async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('WebRTC: createAnswer called before initialize');
    }

    AppLogger.info('WebRTC: SDP Answer oluÅŸturuluyor...');

    final answerConstraints = <String, dynamic>{
      'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
    };

    final answer = await pc.createAnswer(answerConstraints);
    if (answer.sdp == null ||
        answer.sdp!.trim().isEmpty ||
        answer.type == null ||
        answer.type!.trim().isEmpty) {
      throw StateError('WebRTC: createAnswer returned invalid description');
    }

    // SDP Munging: Opus codec ayarlarını optimize et
    final optimizedSdp = _optimizeSdp(answer.sdp!);
    final optimizedAnswer = RTCSessionDescription(optimizedSdp, answer.type);

    await pc.setLocalDescription(optimizedAnswer);
    AppLogger.info('WebRTC: SDP Answer length=${answer.sdp?.length ?? 0}');

    AppLogger.info(
      'WebRTC: SDP Answer oluşturuldu (Optimize edildi) ve LocalDescription set edildi.',
    );
    return optimizedAnswer;
  }

  /// KarÅŸÄ± taraftan gelen SDP'yi (Offer veya Answer) set eder.
  ///
  /// [type] â€” "offer" veya "answer"
  /// [sdp] â€” SDP string
  Future<void> setRemoteDescription(String type, String sdp) async {
    final pc = _peerConnection;
    if (pc == null) {
      throw StateError('WebRTC: setRemoteDescription called before initialize');
    }

    final normalizedType = type.trim().toLowerCase();
    if (normalizedType != 'offer' && normalizedType != 'answer') {
      throw ArgumentError.value(type, 'type', 'must be "offer" or "answer"');
    }

    var normalizedSdp = sdp;
    final lower = normalizedSdp.trim().toLowerCase();
    if (lower == 'null' || lower == 'undefined') {
      throw ArgumentError.value(
        sdp,
        'sdp',
        'setRemoteDescription received invalid sdp literal',
      );
    }
    if (normalizedSdp.trim().isEmpty) {
      throw ArgumentError.value(
        sdp,
        'sdp',
        'setRemoteDescription received empty sdp',
      );
    }
    if (normalizedSdp.contains(r'\u000d\u000a')) {
      normalizedSdp = normalizedSdp.replaceAll(r'\u000d\u000a', '\r\n');
      AppLogger.warning(
        'WebRTC: RemoteDescription SDP had escaped unicode CRLF, normalized.',
      );
    }
    if (normalizedSdp.contains(r'\r\n')) {
      normalizedSdp = normalizedSdp.replaceAll(r'\r\n', '\r\n');
      AppLogger.warning(
        'WebRTC: RemoteDescription SDP had escaped CRLF, normalized.',
      );
    }
    if (!normalizedSdp.contains('\r\n') && normalizedSdp.contains('\n')) {
      normalizedSdp = normalizedSdp.replaceAll('\n', '\r\n');
      AppLogger.warning(
        'WebRTC: RemoteDescription SDP had LF-only line endings, normalized to CRLF.',
      );
    }
    if (!normalizedSdp.contains('\r\n') && normalizedSdp.contains('\r')) {
      normalizedSdp = normalizedSdp.replaceAll('\r', '\r\n');
      AppLogger.warning(
        'WebRTC: RemoteDescription SDP had CR-only line endings, normalized to CRLF.',
      );
    }

    AppLogger.info(
      'WebRTC: RemoteDescription set ediliyor. Type: $type sdpLen=${normalizedSdp.length}',
    );
    if (!normalizedSdp.trimLeft().startsWith('v=')) {
      final preview = normalizedSdp.length <= 40
          ? normalizedSdp
          : '${normalizedSdp.substring(0, 40)}...';
      throw ArgumentError.value(
        sdp,
        'sdp',
        'setRemoteDescription received non-SDP payload (head=$preview)',
      );
    }

    final existingRemote = await pc.getRemoteDescription();
    if (existingRemote != null &&
        existingRemote.type?.toLowerCase() == normalizedType &&
        existingRemote.sdp == normalizedSdp) {
      AppLogger.warning(
        'WebRTC: Duplicate RemoteDescription ignored. Type: $normalizedType',
      );
      return;
    }

    final signalingState = await pc.getSignalingState();
    if (normalizedType == 'answer' &&
        signalingState != null &&
        signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      AppLogger.warning(
        'WebRTC: Remote answer ignored due to signaling state=$signalingState',
      );
      return;
    }
    if (normalizedType == 'offer' &&
        signalingState != null &&
        signalingState != RTCSignalingState.RTCSignalingStateStable) {
      AppLogger.warning(
        'WebRTC: Remote offer ignored due to signaling state=$signalingState',
      );
      return;
    }

    final description = RTCSessionDescription(normalizedSdp, normalizedType);
    try {
      await pc.setRemoteDescription(description);
    } catch (e) {
      throw StateError(
        'WebRTC: setRemoteDescription failed '
        '(type=$normalizedType, sdpLen=${normalizedSdp.length}): $e',
      );
    }
    await _flushPendingIceCandidates(pc);

    AppLogger.info('WebRTC: RemoteDescription set edildi.');
  }

  // ============================================================
  // ICE CANDIDATES
  // ============================================================

  /// Karşı taraftan gelen ICE Candidate'i ekler.
  ///
  /// [candidate] â€” ICE candidate string
  /// [sdpMid] â€” Media stream ID
  /// [sdpMLineIndex] â€” Media line index
  Future<void> addIceCandidate(
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    final pc = _peerConnection;
    if (pc == null) {
      AppLogger.warning(
        'WebRTC: ICE Candidate ignored because PeerConnection is not initialized.',
      );
      return;
    }
    if (candidate.trim().isEmpty) {
      AppLogger.warning('WebRTC: Empty ICE candidate ignored.');
      return;
    }

    final iceCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    final remoteDescription = await pc.getRemoteDescription();
    if (remoteDescription == null) {
      _pendingCandidates.add(iceCandidate);
      AppLogger.warning(
        'WebRTC: RemoteDescription hazir degil, candidate queue\'ya alindi. Pending=${_pendingCandidates.length}',
      );
      return;
    }

    AppLogger.info('WebRTC: ICE Candidate ekleniyor...');
    try {
      await pc.addCandidate(iceCandidate);
      AppLogger.info('WebRTC: ICE Candidate eklendi.');
    } catch (e) {
      _pendingCandidates.add(iceCandidate);
      AppLogger.warning(
        'WebRTC: Candidate eklenemedi, queue\'ya geri alindi. Pending=${_pendingCandidates.length} Error=$e',
      );
    }
  }

  Future<void> _flushPendingIceCandidates(RTCPeerConnection pc) async {
    if (_pendingCandidates.isEmpty) return;

    final queued = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    AppLogger.info(
      'WebRTC: Pending ICE flush basliyor. Count=${queued.length}',
    );

    for (final candidate in queued) {
      try {
        await pc.addCandidate(candidate);
      } catch (e) {
        _pendingCandidates.add(candidate);
        AppLogger.warning(
          'WebRTC: Pending candidate eklenemedi, tekrar kuyruklandi: $e',
        );
      }
    }

    if (_pendingCandidates.isNotEmpty) {
      AppLogger.warning(
        'WebRTC: Pending ICE flush tamamlandi, kalan=${_pendingCandidates.length}',
      );
    } else {
      AppLogger.info('WebRTC: Pending ICE flush tamamlandi.');
    }
  }

  // ============================================================
  // DISPOSE â€” Temizlik
  // ============================================================

  /// TÃ¼m kaynaklarÄ± serbest bÄ±rakÄ±r. Arama bittiÄŸinde Ã§aÄŸrÄ±lmalÄ±.
  Future<void> dispose() async {
    AppLogger.info('WebRTC: Kaynaklar temizleniyor...');

    // Yerel stream'i kapat
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
      _localStreamController.add(null);
    }

    // Uzak stream'i kapat
    if (_remoteStream != null) {
      await _remoteStream!.dispose();
      _remoteStream = null;
      _remoteStreamController.add(null);
    }

    // PeerConnection'Ä± kapat
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    _pendingCandidates.clear();

    _isMicEnabled = true;

    AppLogger.info('WebRTC: TÃ¼m kaynaklar temizlendi.');
  }

  /// TÃ¼m stream controller'larÄ± kapatÄ±r. Servis tamamen yok edilirken Ã§aÄŸrÄ±lÄ±r.
  /// Singleton kullanÄ±ldÄ±ÄŸÄ±nda app lifecycle sonunda Ã§aÄŸrÄ±lmalÄ±.
  void destroy() {
    dispose();
    _remoteStreamController.close();
    _localStreamController.close();
    _iceCandidateController.close();
    _connectionStateController.close();
    _iceGatheringStateController.close();

    AppLogger.info('WebRTC: Service destroy edildi.');
  }

  // ============================================================
  // ORCHESTRATION HELPERS
  // ============================================================

  /// Combine all steps to handle an incoming offer
  Future<String?> handleOffer(String fromUserId, String sdp) async {
    try {
      await stopAll(); // Clean start
      // Note: In a real app, you'd get ICE servers from backend.
      // For now, using default STUN.
      await initialize([]);
      await setRemoteDescription('offer', sdp);
      await startLocalStream();
      final answer = await createAnswer();
      return answer.sdp;
    } catch (e) {
      AppLogger.error("WebRTC: handleOffer failed", e);
      return null;
    }
  }

  /// Combine all steps to handle an incoming answer
  Future<void> handleAnswer(String fromUserId, String sdp) async {
    try {
      await setRemoteDescription('answer', sdp);
    } catch (e) {
      AppLogger.error("WebRTC: handleAnswer failed", e);
    }
  }

  /// Stop all streams and connection
  Future<void> stopAll() async {
    await dispose();
  }

  /// Mevcut bitrate değerini döner (adaptif sistem için).
  int get currentBitrate => _currentBitrate;

  /// SDP (Session Description Protocol) içeriğini manipüle ederek
  /// Opus ses codec'ini düşük gecikme için optimize eder.
  String _optimizeSdp(String sdp) {
    // 1. Opus Payload Type'ı bul (Genellikle 111 ama dinamik olabilir)
    // a=rtpmap:111 opus/48000/2
    final opusMatch = RegExp(r'a=rtpmap:(\d+) opus/48000/2').firstMatch(sdp);
    if (opusMatch == null) return sdp; // Opus bulunamadı

    final payloadType = opusMatch.group(1);

    // 2. İlgili fmtp satırını bul veya oluştur
    // a=fmtp:111 ...
    final fmtpRegex = RegExp('a=fmtp:$payloadType (.*)\r\n');

    // Motosiklet için optimize edilmiş parametreler:
    // usedtx=0 -> Sessizlikte veri kesmeyi kapat (Rüzgarı konuşma sanıp kesmesin)
    // useinbandfec=1 -> Paket kaybı onarımı
    // minptime=10 -> Düşük gecikme (10ms paketler)
    final newParams =
        'a=fmtp:$payloadType minptime=10;useinbandfec=1;maxaveragebitrate=$_currentBitrate;stereo=0;sprop-stereo=0;usedtx=0;cbr=0\r\n';

    if (!sdp.contains(fmtpRegex)) {
      // fmtp satırı yoksa rtpmap'in altına ekle
      return sdp.replaceFirst(
        'a=rtpmap:$payloadType opus/48000/2\r\n',
        'a=rtpmap:$payloadType opus/48000/2\r\n$newParams',
      );
    }

    // fmtp satırı varsa değiştir
    return sdp.replaceAll(fmtpRegex, newParams);
  }

  // [NEW] Stats Tracking for Seamless Fallback
  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final pc = _peerConnection;
      if (pc == null ||
          pc.connectionState !=
              RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        return;
      }

      try {
        final stats = await pc.getStats();
        bool isPoor = false;

        for (final stat in stats) {
          if (stat.type == 'inbound-rtp' && stat.values['kind'] == 'audio') {
            final packetLoss = stat.values['packetsLost'] ?? 0;
            final jitter = stat.values['jitter'] ?? 0;

            // Basit Kalite Algoritmasi
            if (packetLoss > 50 || jitter > 0.05) {
              // 50ms jitter veya asiri kayip
              isPoor = true;
            }
          }
        }

        if (isPoor) {
          _poorQualityCount++;
          if (_poorQualityCount >= 3) {
            _connectionQualityController.add('POOR');
            _poorQualityCount = 0; // Sifirla, surekli tetiklemesin
          }
        } else {
          _poorQualityCount = 0; // Bir iyi raporda sayaci sifirla
          _connectionQualityController.add('GOOD');
        }
      } catch (e) {
        // Stats error ignored
      }
    });
  }
}
