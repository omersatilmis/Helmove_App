/// Profile API'den dönen response DTO
class ProfileResponseDto {
  final bool success;
  final String? message;
  final ProfileDataDto? data;

  ProfileResponseDto({required this.success, this.message, this.data});

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return ProfileResponseDto(
      success: json['success'] ?? true,
      message: json['message'],
      data: json['data'] != null ? ProfileDataDto.fromJson(json['data']) : null,
    );
  }
}

class ProfileDataDto {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? region;
  final String? profileImageUrl;
  final bool shareLocation;
  final bool showProfileToOthers;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;
  final bool isOnline;

  ProfileDataDto({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.bio,
    this.phoneNumber,
    this.address,
    this.city,
    this.region,
    this.profileImageUrl,
    this.shareLocation = false,
    this.showProfileToOthers = true,
    this.latitude,
    this.longitude,
    this.lastSeen,
    this.isOnline = false,
  });

  factory ProfileDataDto.fromJson(Map<String, dynamic> json) {
    // Helper: Gelen sayı int mi String mi dert etmeden int'e çevirir
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return ProfileDataDto(
      id:
          toInt(json['userId'] ?? json['UserId'] ?? json['id'] ?? json['Id']) ??
          0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      bio: json['bio'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      city: json['city'],
      region: json['region'],
      profileImageUrl: json['profileImageUrl'],
      shareLocation: json['shareLocation'] ?? false,
      showProfileToOthers: json['showProfileToOthers'] ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'])
          : null,
      isOnline: json['isOnline'] ?? false,
    );
  }
}
