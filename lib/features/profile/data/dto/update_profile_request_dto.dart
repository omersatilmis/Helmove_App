/// Profil güncelleme isteği DTO
class UpdateProfileRequestDto {
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? region;
  final bool? shareLocation;
  final bool? showProfileToOthers;

  UpdateProfileRequestDto({
    this.firstName,
    this.lastName,
    this.bio,
    this.phoneNumber,
    this.address,
    this.city,
    this.region,
    this.shareLocation,
    this.showProfileToOthers,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
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
