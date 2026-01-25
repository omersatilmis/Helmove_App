/// DTO for forgot password request
class ForgotPasswordRequestDto {
  final String email;

  ForgotPasswordRequestDto({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
