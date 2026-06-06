/// Grup sürüşünde haritada gösterilen diğer bir sürücünün canlı durumu.
class LiveRider {
  final int userId;
  final String? fullName;
  final String? username;
  final String? profilePictureUrl;
  final double lat;
  final double lng;
  final double? heading;
  final double? speedKmh;
  final bool isOrganizer;
  final DateTime updatedAt;

  const LiveRider({
    required this.userId,
    this.fullName,
    this.username,
    this.profilePictureUrl,
    required this.lat,
    required this.lng,
    this.heading,
    this.speedKmh,
    this.isOrganizer = false,
    required this.updatedAt,
  });

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    if (username != null && username!.trim().isNotEmpty) return username!;
    return 'Sürücü';
  }

  /// Konum güncellemesi (lat/lng/heading/speed) gelir; profil bilgisi korunur.
  LiveRider withLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speedKmh,
    required DateTime updatedAt,
  }) {
    return LiveRider(
      userId: userId,
      fullName: fullName,
      username: username,
      profilePictureUrl: profilePictureUrl,
      lat: lat,
      lng: lng,
      heading: heading ?? this.heading,
      speedKmh: speedKmh ?? this.speedKmh,
      isOrganizer: isOrganizer,
      updatedAt: updatedAt,
    );
  }

  /// Profil bilgisi (isim/foto) güncellenir; konum korunur.
  LiveRider withProfile({
    String? fullName,
    String? username,
    String? profilePictureUrl,
    bool? isOrganizer,
  }) {
    return LiveRider(
      userId: userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      lat: lat,
      lng: lng,
      heading: heading,
      speedKmh: speedKmh,
      isOrganizer: isOrganizer ?? this.isOrganizer,
      updatedAt: updatedAt,
    );
  }
}
