/// DTO for OTP-based confirm forgot-password request
class ConfirmForgotPasswordRequestDto {
  final String email;
  final String code;
  final String newPassword;
  final String confirmNewPassword;

  ConfirmForgotPasswordRequestDto({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
      'newPassword': newPassword,
      'confirmNewPassword': confirmNewPassword,
    };
  }
}
