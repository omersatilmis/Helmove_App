class RevokeTokenRequestDto {
  final String refreshToken;
  final bool revokeAll;

  RevokeTokenRequestDto({required this.refreshToken, this.revokeAll = false});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken, 'revokeAll': revokeAll};
  }
}
