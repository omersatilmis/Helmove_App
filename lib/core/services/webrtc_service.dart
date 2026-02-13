import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
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
    };

    final constraints = <String, dynamic>{
      'mandatory': {},
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    _peerConnection = await createPeerConnection(configuration, constraints);
    _registerPeerConnectionCallbacks();

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
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
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
  void setMicrophoneEnabled(bool enabled) {
    if (_localStream == null) return;

    _isMicEnabled = enabled;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = enabled;
    }

    AppLogger.info('WebRTC: Mikrofon â†’ ${enabled ? "aÃ§Ä±k" : "kapalÄ±"}');
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
    await pc.setLocalDescription(offer);
    AppLogger.info('WebRTC: SDP Offer length=${offer.sdp?.length ?? 0}');

    AppLogger.info(
      'WebRTC: SDP Offer oluÅŸturuldu ve LocalDescription set edildi.',
    );
    return offer;
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
    await pc.setLocalDescription(answer);
    AppLogger.info('WebRTC: SDP Answer length=${answer.sdp?.length ?? 0}');

    AppLogger.info(
      'WebRTC: SDP Answer oluÅŸturuldu ve LocalDescription set edildi.',
    );
    return answer;
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
}
