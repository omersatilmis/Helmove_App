import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moto_comm_app_1/core/constants/audio_bitrate.dart';
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
  static const int _poorFloor = AudioBitrate.low; // minimum survival bitrate
  static const Duration _hysteresisDuration = Duration(seconds: 3);

  /// Kullanıcının ayarlardan seçtiği bitrate (tavan).
  int _ceilingBitrate = _defaultCeiling;
  int get ceilingBitrate => _ceilingBitrate;

  /// Sinyal kalitesine göre hesaplanmış efektif bitrate.
  int _effectiveBitrate = _defaultCeiling;
  int get effectiveBitrate => _effectiveBitrate;

  /// Son bilinen sinyal kalitesi.
  IntercomConnectionQuality _lastQuality = IntercomConnectionQuality.unknown;
  IntercomConnectionQuality get lastQuality => _lastQuality;

  /// Hysteresis timer — poor→good geçişinde 3 saniye bekler.
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
    AppLogger.info('AdaptiveBitrate: Ceiling updated -> $bitrate bps');

    // Eğer mevcut efektif tavan değerinin altındaysa ve sinyal iyiyse, yükselt
    if (_lastQuality == IntercomConnectionQuality.excellent ||
        _lastQuality == IntercomConnectionQuality.good ||
        _lastQuality == IntercomConnectionQuality.unknown) {
      _applyBitrate(_ceilingBitrate);
    }
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
      case IntercomConnectionQuality.excellent:
      case IntercomConnectionQuality.good:
        // Sinyal iyileşti — hysteresis ile bekle, sonra yükselt
        _scheduleUpgrade();
        break;

      case IntercomConnectionQuality.poor:
      case IntercomConnectionQuality.lost:
        // Sinyal kötü — HEMEN düşür (gecikme yok)
        _hysteresisTimer?.cancel();
        _hysteresisTimer = null;
        _applyBitrate(_poorFloor);
        break;

      case IntercomConnectionQuality.unknown:
        // Bilinmeyen durumda mevcut bitrate'i koru
        break;
    }
  }

  /// Poor → Good/Excellent geçişinde 3 saniye bekleyip yükseltir.
  /// Bu sayede sinyal kısa süreli dalgalanmalarda gereksiz zıplama olmaz.
  void _scheduleUpgrade() {
    _hysteresisTimer?.cancel();
    _hysteresisTimer = Timer(_hysteresisDuration, () {
      // 3 saniye sonra hâlâ iyi sinyal mi?
      if (_lastQuality == IntercomConnectionQuality.excellent ||
          _lastQuality == IntercomConnectionQuality.good) {
        _applyBitrate(_ceilingBitrate);
        AppLogger.info(
          'AdaptiveBitrate: Hysteresis passed -> upgrading to ceiling '
          '($_ceilingBitrate bps)',
        );
      }
    });
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
