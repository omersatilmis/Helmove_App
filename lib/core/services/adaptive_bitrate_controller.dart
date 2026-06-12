import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helmove/core/constants/audio_bitrate.dart';
import '../utils/app_logger.dart';
import '../../features/intercom/domain/intercom_models.dart';

/// Sinyal kalitesine göre bitrate'i otomatik ayarlayan controller.
///
/// Kullanıcının seçtiği ses kalitesi "tavan" (ceiling) olarak alınır.
/// Sinyal zayıfladığında bitrate düşürülür, güçlendiğinde tavana geri döner.
/// Hysteresis ile hızlı dalgalanmalar (oscillation) önlenir.
class AdaptiveBitrateController {
  static const String _prefKey = 'audio_quality_key';
  static const int _defaultCeiling = AudioBitrate.medium; // medium
  // Düşüş tabanı 24 kbps: Opus için sesli iletişimde yeterli; 16k'ya inip
  // tavana geri zıplama (16k↔32k flapping) yerine kararlı bir alt seviye.
  static const int _degradedFloor = 24000;
  static const int _warningFloor = AudioBitrate.medium;
  static const Duration _hysteresisDuration = Duration(seconds: 15);

  /// Kullanıcı tavanı 24k'dan düşükse (low=16k seçiliyse) tavan geçerli olur.
  int get _poorFloor =>
      _degradedFloor > _ceilingBitrate ? _ceilingBitrate : _degradedFloor;

  // Network metric thresholds (tuned for voice comm).
  static const double _criticalPacketLossPercent = 12.0;
  static const double _criticalJitterMs = 80.0;
  static const double _criticalRttMs = 450.0;

  static const double _warningPacketLossPercent = 5.0;
  static const double _warningJitterMs = 35.0;
  static const double _warningRttMs = 220.0;

  /// Kullanıcının ayarlardan seçtiği bitrate (tavan).
  int _ceilingBitrate = _defaultCeiling;
  int get ceilingBitrate => _ceilingBitrate;

  /// Sinyal kalitesine göre hesaplanmış efektif bitrate.
  int _effectiveBitrate = _defaultCeiling;
  int get effectiveBitrate => _effectiveBitrate;

  /// Son bilinen sinyal kalitesi.
  IntercomConnectionQuality _lastQuality = IntercomConnectionQuality.unknown;
  IntercomConnectionQuality get lastQuality => _lastQuality;

  int _qualityCap = _defaultCeiling;
  int _metricsCap = _defaultCeiling;

  /// Hysteresis timer — poor→good geçişinde [_hysteresisDuration] bekler.
  Timer? _hysteresisTimer;

  /// Bitrate değişikliklerini dinleyenler için stream.
  final _bitrateController = StreamController<int>.broadcast();
  Stream<int> get bitrate$ => _bitrateController.stream;

  AdaptiveBitrateController() {
    _loadCeiling();
  }

  /// SharedPreferences'den kullanıcının seçtiği kaliteyi yükle.
  Future<void> _loadCeiling() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_prefKey);
      _ceilingBitrate = _keyToBitrate(key);
      _qualityCap = _ceilingBitrate;
      _metricsCap = _ceilingBitrate;
      _effectiveBitrate = _ceilingBitrate;
      AppLogger.info(
        'AdaptiveBitrate: Ceiling loaded -> $_ceilingBitrate bps (key=$key)',
      );
    } catch (e) {
      AppLogger.error('AdaptiveBitrate: Failed to load ceiling', e);
    }
  }

  /// Kullanıcı ayarlardan ses kalitesini değiştirdiğinde çağrılır.
  void updateCeiling(int bitrate) {
    _ceilingBitrate = bitrate;
    _qualityCap = _qualityCap.clamp(_poorFloor, _ceilingBitrate);
    _metricsCap = _metricsCap.clamp(_poorFloor, _ceilingBitrate);
    AppLogger.info('AdaptiveBitrate: Ceiling updated -> $bitrate bps');

    _recomputeAndApply(reason: 'ceiling_update');
  }

  /// SharedPreferences key'i üzerinden ceiling'i güncelle.
  /// IntercomEngine.onAudioSettingsChanged() tarafından kullanılır.
  void updateCeilingFromKey(String? key) {
    updateCeiling(_keyToBitrate(key));
  }

  /// Sinyal kalitesi değiştiğinde çağrılır (LiveKit quality stream'den).
  void onQualityChanged(IntercomConnectionQuality quality) {
    if (quality == _lastQuality) return;

    final previousQuality = _lastQuality;
    _lastQuality = quality;

    AppLogger.info(
      'AdaptiveBitrate: Quality changed -> ${quality.name} '
      '(was: ${previousQuality.name})',
    );

    switch (quality) {
      case IntercomConnectionQuality.ultra:
        _qualityCap = _ceilingBitrate;
        _recomputeAndApply(reason: 'quality_ultra');
        break;

      case IntercomConnectionQuality.high:
        _qualityCap = AudioBitrate.high.clamp(_poorFloor, _ceilingBitrate);
        _recomputeAndApply(reason: 'quality_high');
        break;

      case IntercomConnectionQuality.balanced:
        _qualityCap = AudioBitrate.medium.clamp(_poorFloor, _ceilingBitrate);
        _recomputeAndApply(reason: 'quality_balanced');
        break;

      case IntercomConnectionQuality.low:
      case IntercomConnectionQuality.lost:
        // Sinyal kötü — HEMEN düşür (gecikme yok)
        _qualityCap = _poorFloor;
        _recomputeAndApply(reason: 'quality_degraded');
        break;

      case IntercomConnectionQuality.unknown:
        // Bilinmeyen durumda mevcut bitrate'i koru
        break;
    }
  }

  /// Runtime ağ metriklerine göre adaptif cap günceller.
  ///
  /// - Kritik durumda: low
  /// - Uyarı durumunda: medium
  /// - Sağlıklı durumda: ceiling (kullanıcı seçimi / varsayılan)
  void onNetworkMetrics({
    required double packetLossPercent,
    required double jitterMs,
    required double rttMs,
  }) {
    final isCritical =
        packetLossPercent >= _criticalPacketLossPercent ||
        jitterMs >= _criticalJitterMs ||
        rttMs >= _criticalRttMs;

    final isWarning =
        packetLossPercent >= _warningPacketLossPercent ||
        jitterMs >= _warningJitterMs ||
        rttMs >= _warningRttMs;

    if (isCritical) {
      _metricsCap = _poorFloor;
      _recomputeAndApply(reason: 'metrics_critical');
      return;
    }

    if (isWarning) {
      _metricsCap = _warningFloor.clamp(_poorFloor, _ceilingBitrate);
      _recomputeAndApply(reason: 'metrics_warning');
      return;
    }

    _metricsCap = _ceilingBitrate;
    _recomputeAndApply(reason: 'metrics_recovered');
  }

  /// Poor → Good/Excellent geçişinde [_hysteresisDuration] bekleyip yükseltir.
  /// Bu sayede sinyal kısa süreli dalgalanmalarda gereksiz zıplama olmaz.
  void _scheduleUpgrade() {
    _hysteresisTimer?.cancel();
    _hysteresisTimer = Timer(_hysteresisDuration, () {
      // Süre dolunca hâlâ iyileşme yönünde mi?
      final stillRecovering =
          _lastQuality != IntercomConnectionQuality.low &&
          _lastQuality != IntercomConnectionQuality.lost;
      if (!stillRecovering) return;

      // Timer beklerken caps değişmiş olabilir — güncel hedefi uygula.
      final target = _currentTarget();
      _applyBitrate(target);
      AppLogger.info(
        'AdaptiveBitrate: Hysteresis passed -> upgrading to $target bps',
      );
    });
  }

  int _currentTarget() =>
      (_qualityCap < _metricsCap ? _qualityCap : _metricsCap).clamp(
        _poorFloor,
        _ceilingBitrate,
      );

  void _recomputeAndApply({required String reason}) {
    final target = _currentTarget();

    // Düşüş (veya aynı seviye) her zaman anında uygulanır.
    if (target <= _effectiveBitrate) {
      _hysteresisTimer?.cancel();
      _hysteresisTimer = null;
      _applyBitrate(target);
      return;
    }

    // Yükseliş hiçbir zaman anında uygulanmaz, her zaman hysteresis bekler.
    // Aktif bir timer varsa yeniden kurma — aksi halde her 2 saniyede gelen
    // metrics_recovered olayı timer'ı sürekli sıfırlayıp yükselişi açlığa
    // (starvation) sokuyordu.
    if (_hysteresisTimer?.isActive ?? false) return;

    AppLogger.info(
      'AdaptiveBitrate: Recovery pending ($reason) -> schedule $target bps',
    );
    _scheduleUpgrade();
  }

  /// Efektif bitrate'i güncelle ve stream'e yayınla.
  void _applyBitrate(int bitrate) {
    // Tavan değerini aşma
    final clamped = bitrate.clamp(_poorFloor, _ceilingBitrate);
    if (clamped == _effectiveBitrate) return;

    _effectiveBitrate = clamped;
    _bitrateController.add(clamped);
    AppLogger.info(
      'AdaptiveBitrate: Effective bitrate -> $clamped bps '
      '(ceiling=$_ceilingBitrate, quality=${_lastQuality.name})',
    );
  }

  /// SharedPreferences key'ini bitrate değerine çevir.
  int _keyToBitrate(String? key) {
    switch (key) {
      case 'low':
        return AudioBitrate.low;
      case 'medium':
        return AudioBitrate.medium;
      case 'high':
        return AudioBitrate.high;
      case 'ultra':
        return AudioBitrate.ultra;
      default:
        return _defaultCeiling;
    }
  }

  void dispose() {
    _hysteresisTimer?.cancel();
    _bitrateController.close();
  }
}
