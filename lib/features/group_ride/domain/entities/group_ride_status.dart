/// Grup sürüşü yaşam döngüsü durumu.
///
/// Backend `GroupRideStatus` enum'una karşılık gelir. Entity'de durum bir
/// String olarak tutulduğu için [parseGroupRideStatus] ile bu enum'a çevrilir.
enum GroupRideStatus {
  /// Oluşturuldu, katılım toplanıyor.
  planning,

  /// Onaylanmış, başlamaya hazır.
  active,

  /// Canlı sürüş — herkes yolda.
  inProgress,

  /// Tamamlandı.
  completed,

  /// İptal edildi.
  cancelled,

  /// Ertelendi.
  postponed,

  /// Bilinmeyen / eşleşmeyen durum.
  unknown,
}

/// Backend'den gelen durum string'ini (`"Planning"`, `"InProgress"` vb.)
/// [GroupRideStatus] enum'una çevirir. Büyük/küçük harf duyarsızdır.
GroupRideStatus parseGroupRideStatus(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'planning':
      return GroupRideStatus.planning;
    case 'active':
      return GroupRideStatus.active;
    case 'inprogress':
    case 'in_progress':
      return GroupRideStatus.inProgress;
    case 'completed':
      return GroupRideStatus.completed;
    case 'cancelled':
    case 'canceled':
      return GroupRideStatus.cancelled;
    case 'postponed':
      return GroupRideStatus.postponed;
    default:
      return GroupRideStatus.unknown;
  }
}

extension GroupRideStatusX on GroupRideStatus {
  /// Tur sona ermiş mi (tamamlandı / iptal edildi)? Terminal durumlarda
  /// organizatör aksiyon butonları gizlenir.
  bool get isTerminal =>
      this == GroupRideStatus.completed || this == GroupRideStatus.cancelled;

  /// Canlı sürüş (InProgress) mü?
  bool get isLive => this == GroupRideStatus.inProgress;

  /// Henüz başlamamış ve başlatılabilir bir durumda mı (planlanıyor / hazır /
  /// ertelenmiş)? Bu durumlarda Başlat/Ertele/İptal aksiyonları gösterilir.
  bool get isStartable =>
      this == GroupRideStatus.planning ||
      this == GroupRideStatus.active ||
      this == GroupRideStatus.postponed;
}
