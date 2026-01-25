import '../entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthEntity> login(String email, String password);

  Future<void> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<void> logout();

  Future<bool> isLoggedIn();

  /// Şifremi unuttum - Email'e sıfırlama linki gönderir
  Future<void> forgotPassword(String email);

  /// Şifre sıfırlama - Mevcut şifre ile yeni şifre belirleme
  Future<void> resetPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  });
}
