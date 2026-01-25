import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../dto/login_request_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/forgot_password_request_dto.dart';
import '../dto/reset_password_request_dto.dart';
import '../mapper/auth_mapper.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/utils/app_logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<AuthEntity> login(String email, String password) async {
    try {
      final requestDto = LoginRequestDto(email: email, password: password);
      final responseDto = await _remoteDataSource.login(requestDto);

      if (!responseDto.success || responseDto.data == null) {
        throw Exception(responseDto.message ?? "Giriş başarısız");
      }

      await _localDataSource.saveToken(responseDto.data!.token);
      return AuthMapper.toEntity(responseDto);
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
      await _remoteDataSource.logout();
    } catch (e) {
      AppLogger.warning("Logout API error: $e");
    } finally {
      await _localDataSource.deleteToken();
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _localDataSource.getToken();
    return token != null && token.isNotEmpty;
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
}
