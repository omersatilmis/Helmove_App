import '../api/auth_api.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/register_response_dto.dart';
import '../dto/forgot_password_request_dto.dart';
import '../dto/confirm_forgot_password_request_dto.dart';
import '../dto/reset_password_request_dto.dart';
import '../dto/refresh_token_request_dto.dart';
import '../dto/revoke_token_request_dto.dart';
import '../dto/session_dto.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseDto> login(LoginRequestDto request);
  Future<RegisterResponseDto> register(RegisterRequestDto request);
  Future<void> logout({RevokeTokenRequestDto? request});
  Future<void> forgotPassword(ForgotPasswordRequestDto request);
  Future<void> confirmForgotPassword(ConfirmForgotPasswordRequestDto request);
  Future<void> resetPassword(ResetPasswordRequestDto request);

  // New methods
  Future<LoginResponseDto> refreshToken(RefreshTokenRequestDto request);
  Future<void> revokeToken(RevokeTokenRequestDto request);
  Future<List<SessionDto>> getSessions();
  Future<LoginResponseDto> refreshCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthApi api;

  AuthRemoteDataSourceImpl({required this.api});

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    return await api.login(request);
  }

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    return await api.register(request);
  }

  @override
  Future<void> logout({RevokeTokenRequestDto? request}) async {
    return await api.logout(request: request);
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequestDto request) async {
    return await api.forgotPassword(request);
  }

  @override
  Future<void> confirmForgotPassword(
    ConfirmForgotPasswordRequestDto request,
  ) async {
    return await api.confirmForgotPassword(request);
  }

  @override
  Future<void> resetPassword(ResetPasswordRequestDto request) async {
    return await api.resetPassword(request);
  }

  @override
  Future<LoginResponseDto> refreshToken(RefreshTokenRequestDto request) async {
    return await api.refreshToken(request);
  }

  @override
  Future<void> revokeToken(RevokeTokenRequestDto request) async {
    return await api.revokeToken(request);
  }

  @override
  Future<List<SessionDto>> getSessions() async {
    return await api.getSessions();
  }

  @override
  Future<LoginResponseDto> refreshCurrentUser() async {
    return await api.refreshCurrentUser();
  }
}
