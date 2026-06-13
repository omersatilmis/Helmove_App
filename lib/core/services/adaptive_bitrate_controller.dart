import 'dart:async';
import '../utils/app_logger.dart';
import '../../features/intercom/domain/intercom_models.dart';

/// Ses bitrate'ini SABİT tutan controller.
///
/// Önceden sinyal kalitesine göre bitrate'i dinamik olarak değiştiriyordu.
/// Ancak grup sürüşünde (SFU/LiveKit) her bitrate değişimi ses track'inin
/// yeniden publish edilmesine (`publishAudioTrack`) yol açıyor ve bu da
/// anlık ses kesilmelerine sebep oluyordu. Mesaj aramalarında (P2P/WebRTC)
/// bitrate değişimi yalnızca sender parametresini güncellediği için kesinti
/// olmuyordu — sorun yalnızca grup sürüşündeydi.
///
/// Bu yüzden adaptif sistem tamamen devre dışı bırakıldı: bitrate her zaman
/// 24 kbps'de sabit kalır, hiçbir koşulda (sinyal kalitesi, ağ metrikleri,
/// kullanıcı ayarı) değiştirilmez. Sabit bitrate, track'in tek seferde
/// yayınlanıp bir daha dokunulmaması demektir — yani ses kesintisi olmaz.
class AdaptiveBitrateController {
  /// Sabit ses bitrate'i (24 kbps). Opus için sesli iletişimde yeterli
  /// kalite sağlar ve kesinlikle değiştirilmez.
  static const int _fixedBitrate = 24000;

  /// Geriye dönük uyumluluk için korunan getter'lar — her zaman sabit değer.
  int get ceilingBitrate => _fixedBitrate;
  int get effectiveBitrate => _fixedBitrate;

  /// Son bilinen sinyal kalitesi (yalnızca raporlama/telemetri amaçlı,
  /// bitrate'i etkilemez).
  IntercomConnectionQuality _lastQuality = IntercomConnectionQuality.unknown;
  IntercomConnectionQuality get lastQuality => _lastQuality;

  /// Bitrate stream'i — sabit bitrate hiç değişmediği için hiçbir zaman
  /// yeni değer yaymaz. Aboneler (WebRTC/LiveKit) yalnızca başlangıçtaki
  /// ceiling değerini kullanır.
  final _bitrateController = StreamController<int>.broadcast();
  Stream<int> get bitrate$ => _bitrateController.stream;

  AdaptiveBitrateController() {
    AppLogger.info(
      'AdaptiveBitrate: Sabit mod aktif -> $_fixedBitrate bps (adaptif kapalı)',
    );
  }

  /// Kullanıcı ayarından gelen kalite değişikliği — bitrate sabit olduğu için
  /// yok sayılır.
  void updateCeiling(int bitrate) {
    // No-op: bitrate sabit 24 kbps, değiştirilmez.
  }

  /// SharedPreferences key'i üzerinden ceiling — yok sayılır.
  void updateCeilingFromKey(String? key) {
    // No-op: bitrate sabit 24 kbps, değiştirilmez.
  }

  /// Sinyal kalitesi değişimi — bitrate'i etkilemez, yalnızca son durumu tutar.
  void onQualityChanged(IntercomConnectionQuality quality) {
    _lastQuality = quality;
  }

  /// Ağ metrikleri — bitrate sabit olduğu için yok sayılır.
  void onNetworkMetrics({
    required double packetLossPercent,
    required double jitterMs,
    required double rttMs,
  }) {
    // No-op: bitrate sabit 24 kbps, ağ metriklerine göre değiştirilmez.
  }

  void dispose() {
    _bitrateController.close();
  }
}
