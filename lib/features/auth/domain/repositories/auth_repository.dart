import '../../../../core/enums/user_tier.dart';
import '../entities/auth_entity.dart';
import '../../data/dto/refresh_token_request_dto.dart';
import '../../data/dto/revoke_token_request_dto.dart';
import '../../data/dto/session_dto.dart';

abstract class AuthRepository {
  Future<AuthEntity> login(
    String email,
    String password, {
    bool rememberMe = true,
  });

  Future<AuthEntity> socialSignIn({
    required String provider,
    required String idToken,
    String? accessToken,
    String? authorizationCode,
    String? email,
    String? displayName,
    bool rememberMe = true,
  });

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

  /// Yerel bellekte saklanan kullanıcı verilerini getirir
  Future<AuthEntity?> getPersistedUser();

  /// Saklanan token'ı getirir
  Future<String?> getAuthToken();

  /// Kullanıcı bilgilerini yerel belleğe kaydeder
  Future<void> savePersistedUser(
    int id,
    String username, {
    required String email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    UserTier? tier,
  });

  /// Şifremi unuttum - Email'e sıfırlama linki gönderir
  Future<void> forgotPassword(String email);

  /// Şifremi unuttum - Token ile yeni şifre belirleme
  Future<void> confirmForgotPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  });

  /// Şifre sıfırlama - Mevcut şifre ile yeni şifre belirleme
  Future<void> resetPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  });

  Future<void> refreshToken(RefreshTokenRequestDto request);
  Future<void> revokeToken(RevokeTokenRequestDto request);
  Future<List<SessionDto>> getSessions();

  /// Mevcut kullanıcı bilgilerini API'den tekrar çeker ve yerel cache'i günceller
  Future<AuthEntity> refreshCurrentUser();
}
