/// DTO for reset password request
class ResetPasswordRequestDto {
  final String email;
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  ResetPasswordRequestDto({
    required this.email,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmNewPassword': confirmNewPassword,
    };
  }
}
