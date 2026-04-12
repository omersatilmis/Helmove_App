import '../../../../core/enums/user_tier.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/login_request_dto.dart';
import '../dto/social_sign_in_request_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/forgot_password_request_dto.dart';
import '../dto/confirm_forgot_password_request_dto.dart';
import '../dto/reset_password_request_dto.dart';
import '../dto/refresh_token_request_dto.dart';
import '../dto/revoke_token_request_dto.dart';
import '../dto/session_dto.dart';
import '../mapper/auth_mapper.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/services/subscription_service.dart';
import 'package:helmove/core/di/injection_container.dart';
import 'package:flutter/foundation.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<AuthEntity> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final requestDto = LoginRequestDto(email: email, password: password);
      final responseDto = await _remoteDataSource.login(requestDto);

      if (!responseDto.success || responseDto.data == null) {
        throw Exception(responseDto.message ?? "Giriş başarısız");
      }

      final entity = AuthMapper.toEntity(responseDto);

      // Token ve kullanıcı bilgilerini kaydet
      await _localDataSource.saveToken(entity.token);
      final refreshToken = responseDto.data?.refreshToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _localDataSource.saveRefreshToken(refreshToken);
      }
      await _localDataSource.saveUserId(entity.id);
      await _localDataSource.saveUsername(entity.username);
      await _localDataSource.saveEmail(entity.email);
      await _localDataSource.saveFirstName(entity.firstName);
      await _localDataSource.saveLastName(entity.lastName);
      await _localDataSource.saveProfileImageUrl(entity.profileImageUrl);
      await _localDataSource.saveTier(entity.tier);
      await _localDataSource.saveRememberMe(rememberMe);

      // ────────────────────────────────────────────────────────
      // 💳 REVENUECAT LOGIN SYNC
      // ────────────────────────────────────────────────────────
      try {
        if (sl.isRegistered<SubscriptionService>()) {
          await sl<SubscriptionService>().logIn(entity.id.toString());
          debugPrint('✅ RevenueCat user logged in: ${entity.id}');
        }
      } catch (e) {
        debugPrint('❌ RevenueCat login failed: $e');
      }

      return entity;
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<AuthEntity> socialSignIn({
    required String provider,
    required String idToken,
    String? accessToken,
    String? authorizationCode,
    String? email,
    String? displayName,
    bool rememberMe = true,
  }) async {
    try {
      final requestDto = SocialSignInRequestDto(
        provider: provider,
        idToken: idToken,
        accessToken: accessToken,
        authorizationCode: authorizationCode,
        email: email,
        displayName: displayName,
      );
      final responseDto = await _remoteDataSource.socialSignIn(requestDto);

      if (!responseDto.success || responseDto.data == null) {
        throw Exception(responseDto.message ?? "Sosyal giriş başarısız");
      }

      final entity = AuthMapper.toEntity(responseDto);

      await _localDataSource.saveToken(entity.token);
      final refreshToken = responseDto.data?.refreshToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _localDataSource.saveRefreshToken(refreshToken);
      }
      await _localDataSource.saveUserId(entity.id);
      await _localDataSource.saveUsername(entity.username);
      await _localDataSource.saveEmail(entity.email);
      await _localDataSource.saveFirstName(entity.firstName);
      await _localDataSource.saveLastName(entity.lastName);
      await _localDataSource.saveProfileImageUrl(entity.profileImageUrl);
      await _localDataSource.saveTier(entity.tier);
      await _localDataSource.saveRememberMe(rememberMe);

      try {
        if (sl.isRegistered<SubscriptionService>()) {
          await sl<SubscriptionService>().logIn(entity.id.toString());
          debugPrint('✅ RevenueCat user logged in: ${entity.id}');
        }
      } catch (e) {
        debugPrint('❌ RevenueCat login failed: $e');
      }

      return entity;
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final requestDto = RegisterRequestDto(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      final responseDto = await _remoteDataSource.register(requestDto);

      if (!responseDto.success) {
        throw Exception(responseDto.message ?? "Kayıt başarısız");
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _localDataSource.getRefreshToken();
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _remoteDataSource.logout(
          request: RevokeTokenRequestDto(refreshToken: refreshToken),
        );
      } else {
        await _remoteDataSource.logout();
      }
    } catch (e) {
      AppLogger.warning("Logout API error: $e");
    } finally {
      // ────────────────────────────────────────────────────────
      // 💳 REVENUECAT LOGOUT SYNC
      // ────────────────────────────────────────────────────────
      try {
        if (sl.isRegistered<SubscriptionService>()) {
          await sl<SubscriptionService>().logOut();
          debugPrint('✅ RevenueCat user logged out');
        }
      } catch (e) {
        debugPrint('❌ RevenueCat logout error: $e');
      }

      await _localDataSource.clearAuthData();
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<AuthEntity?> getPersistedUser() async {
    final token = await _localDataSource.getToken();
    final id = await _localDataSource.getUserId();
    final username = await _localDataSource.getUsername();
    final email = await _localDataSource.getEmail();
    final firstName = await _localDataSource.getFirstName();
    final lastName = await _localDataSource.getLastName();
    final profileImageUrl = await _localDataSource.getProfileImageUrl();
    final tier = await _localDataSource.getTier();

    if (token != null &&
        token.isNotEmpty &&
        id != null &&
        username != null &&
        username.isNotEmpty) {
      return AuthEntity(
        id: id,
        username: username,
        email: email ?? '',
        token: token,
        firstName: firstName,
        lastName: lastName,
        profileImageUrl: profileImageUrl,
        tier: tier,
      );
    }
    return null;
  }

  @override
  Future<String?> getAuthToken() async {
    return _localDataSource.getToken();
  }

  @override
  Future<void> savePersistedUser(
    int id,
    String username, {
    required String email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    UserTier? tier,
  }) async {
    await _localDataSource.saveUserId(id);
    await _localDataSource.saveUsername(username);
    await _localDataSource.saveEmail(email);
    await _localDataSource.saveFirstName(firstName);
    await _localDataSource.saveLastName(lastName);
    await _localDataSource.saveProfileImageUrl(profileImageUrl);
    if (tier != null) {
      await _localDataSource.saveTier(tier);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      final requestDto = ForgotPasswordRequestDto(email: email);
      await _remoteDataSource.forgotPassword(requestDto);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final requestDto = ConfirmForgotPasswordRequestDto(
        email: email,
        code: code,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      await _remoteDataSource.confirmForgotPassword(requestDto);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final requestDto = ResetPasswordRequestDto(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      await _remoteDataSource.resetPassword(requestDto);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> refreshToken(RefreshTokenRequestDto request) async {
    try {
      final responseDto = await _remoteDataSource.refreshToken(request);
      if (responseDto.success && responseDto.data != null) {
        await _localDataSource.saveToken(responseDto.data!.token);
        final refreshToken = responseDto.data!.refreshToken;
        if (refreshToken != null && refreshToken.trim().isNotEmpty) {
          await _localDataSource.saveRefreshToken(refreshToken);
        }
      }
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> revokeToken(RevokeTokenRequestDto request) async {
    try {
      await _remoteDataSource.revokeToken(request);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<List<SessionDto>> getSessions() async {
    try {
      return await _remoteDataSource.getSessions();
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<AuthEntity> refreshCurrentUser() async {
    try {
      final responseDto = await _remoteDataSource.refreshCurrentUser();

      if (!responseDto.success || responseDto.data == null) {
        throw Exception(responseDto.message ?? "Kullanıcı yenileme başarısız");
      }

      final entity = AuthMapper.toEntity(responseDto);

      // Token ve kullanıcı bilgilerini güncelle
      await _localDataSource.saveToken(entity.token);
      final refreshToken = responseDto.data?.refreshToken;
      if (refreshToken != null && refreshToken.trim().isNotEmpty) {
        await _localDataSource.saveRefreshToken(refreshToken);
      }
      await _localDataSource.saveUserId(entity.id);
      await _localDataSource.saveUsername(entity.username);
      await _localDataSource.saveEmail(entity.email);
      await _localDataSource.saveFirstName(entity.firstName);
      await _localDataSource.saveLastName(entity.lastName);
      await _localDataSource.saveProfileImageUrl(entity.profileImageUrl);
      await _localDataSource.saveTier(entity.tier);

      return entity;
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }
}
