class LoginResponseDto {
  final bool success;
  final String? message;
  final LoginDataDto? data;

  LoginResponseDto({required this.success, this.message, this.data});

  // Backend'den gelen JSON'ı okuyoruz
  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      success: json['success'] ?? json['Success'] ?? false,
      message: json['message'] ?? json['Message'],
      data: (json['data'] ?? json['Data']) != null
          ? LoginDataDto.fromJson(json['data'] ?? json['Data'])
          : null,
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
          json['AccessToken'] ??
          json['token'] ??
          json['Token'] ??
          '',
      id: toInt(
        json['userId'] ??
            json['UserId'] ??
            json['id'] ??
            json['Id'] ??
            json['userID'],
      ),
      username: json['username'] ?? json['Username'],
      email: json['email'] ?? json['Email'],
      firstName: json['firstName'] ?? json['FirstName'],
      lastName: json['lastName'] ?? json['LastName'],
      profileImageUrl: json['profileImageUrl'] ?? json['ProfileImageUrl'],
    );
  }
}
