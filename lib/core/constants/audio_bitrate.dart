/// Ses kalitesi için standart bitrate değerleri (bps).
class AudioBitrate {
  /// Low Quality (16 kbps) - Veri Tasarrufu / Düşük Bant Genişliği
  static const int low = 16000;

  /// Medium Quality (32 kbps) - Dengeli / Varsayılan
  static const int medium = 32000;

  /// High Quality (48 kbps) - Yüksek Kalite / WiFi
  static const int high = 48000;

  /// Ultra Quality (64 kbps) - Stüdyo Kalitesi
  static const int ultra = 64000;

  /// Private constructor to prevent instantiation
  const AudioBitrate._();
}
