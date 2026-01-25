class LoginRequestDto {
  final String email;
  final String password;

  LoginRequestDto({required this.email, required this.password});

  // Backend'e gönderirken JSON'a çeviriyoruz
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
