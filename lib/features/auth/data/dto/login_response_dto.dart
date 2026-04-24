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
  // Access token
  final String token;

  // Refresh token (rotation enabled)
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;

  // Access token metadata
  final int? expiresIn;
  final String? tokenType;

  // User fields
  final int? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final String? premiumTier;
  final bool isNewUser;

  LoginDataDto({
    required this.token,
    this.refreshToken,
    this.refreshTokenExpiresAt,
    this.expiresIn,
    this.tokenType,
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    this.premiumTier,
    this.isNewUser = false,
  });

  factory LoginDataDto.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }


    DateTime? toDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return LoginDataDto(
      token:
          json['accessToken'] ??
          json['AccessToken'] ??
          json['token'] ??
          json['Token'] ??
          '',
      refreshToken: (json['refreshToken'] ?? json['RefreshToken'])?.toString(),
      refreshTokenExpiresAt: toDateTime(
        json['refreshTokenExpiresAt'] ?? json['RefreshTokenExpiresAt'],
      ),
      expiresIn: toInt(json['expiresIn'] ?? json['ExpiresIn']),
      tokenType: (json['tokenType'] ?? json['TokenType'])?.toString(),
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
      premiumTier:
          (json['premiumTier'] ?? json['PremiumTier'] ?? json['PremiumTier'])
              ?.toString(),
      isNewUser:
          json['isNewUser'] ?? json['IsNewUser'] ?? json['is_new_user'] ?? false,
    );
  }
}
