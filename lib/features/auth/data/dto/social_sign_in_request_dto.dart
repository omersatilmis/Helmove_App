class SocialSignInRequestDto {
  final String provider;
  final String idToken;
  final String? accessToken;
  final String? authorizationCode;
  final String? email;
  final String? displayName;

  SocialSignInRequestDto({
    required this.provider,
    required this.idToken,
    this.accessToken,
    this.authorizationCode,
    this.email,
    this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'idToken': idToken,
      if (accessToken != null && accessToken!.trim().isNotEmpty)
        'accessToken': accessToken,
      if (authorizationCode != null && authorizationCode!.trim().isNotEmpty)
        'authorizationCode': authorizationCode,
      if (email != null && email!.trim().isNotEmpty) 'email': email,
      if (displayName != null && displayName!.trim().isNotEmpty)
        'displayName': displayName,
    };
  }
}
