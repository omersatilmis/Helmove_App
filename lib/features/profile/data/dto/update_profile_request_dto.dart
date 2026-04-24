/// Profil güncelleme isteği DTO
class UpdateProfileRequestDto {
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? region;
  final bool? shareLocation;
  final bool? showProfileToOthers;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? twitterUrl;

  UpdateProfileRequestDto({
    this.username,
    this.firstName,
    this.lastName,
    this.bio,
    this.phoneNumber,
    this.address,
    this.city,
    this.region,
    this.shareLocation,
    this.showProfileToOthers,
    this.instagramUrl,
    this.youtubeUrl,
    this.twitterUrl,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (username != null) json['username'] = username;
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (bio != null) json['bio'] = bio;
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (address != null) json['address'] = address;
    if (city != null) json['city'] = city;
    if (region != null) json['region'] = region;
    if (shareLocation != null) json['shareLocation'] = shareLocation;
    if (showProfileToOthers != null) {
      json['showProfileToOthers'] = showProfileToOthers;
    }
    if (instagramUrl != null) json['instagramUrl'] = instagramUrl;
    if (youtubeUrl != null) json['youtubeUrl'] = youtubeUrl;
    if (twitterUrl != null) json['twitterUrl'] = twitterUrl;
    return json;
  }
}

/// Konum güncelleme isteği DTO
class UpdateLocationRequestDto {
  final double latitude;
  final double longitude;

  UpdateLocationRequestDto({required this.latitude, required this.longitude});

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}
