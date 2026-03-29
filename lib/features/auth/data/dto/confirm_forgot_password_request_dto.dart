/// DTO for confirm forgot-password request
class ConfirmForgotPasswordRequestDto {
  final String token;
  final String newPassword;
  final String confirmNewPassword;

  ConfirmForgotPasswordRequestDto({
    required this.token,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'newPassword': newPassword,
      'confirmNewPassword': confirmNewPassword,
    };
  }
}
