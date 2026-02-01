class LoginResponseDto {
  final bool success;
  final String? message;
  final LoginDataDto? data;

  LoginResponseDto({required this.success, this.message, this.data});

  // Backend'den gelen JSON'ı okuyoruz
  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? LoginDataDto.fromJson(json['data']) : null,
    );
  }
}

class LoginDataDto {
  final String token;
  final int? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;

  LoginDataDto({
    required this.token,
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
  });

  factory LoginDataDto.fromJson(Map<String, dynamic> json) {
    // Helper: Gelen sayı int mi String mi dert etmeden int'e çevirir
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return LoginDataDto(
      token:
          json['accessToken'] ??
          json['token'] ??
          '', // accessToken veya token olarak gelebilir
      id: toInt(json['userId'] ?? json['id'] ?? json['Id']),
      username: json['username'] ?? json['Username'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}
