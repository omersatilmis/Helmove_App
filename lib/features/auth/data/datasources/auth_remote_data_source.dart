import '../api/auth_api.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/register_response_dto.dart';
import '../dto/forgot_password_request_dto.dart';
import '../dto/reset_password_request_dto.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseDto> login(LoginRequestDto request);
  Future<RegisterResponseDto> register(RegisterRequestDto request);
  Future<void> logout();
  Future<void> forgotPassword(ForgotPasswordRequestDto request);
  Future<void> resetPassword(ResetPasswordRequestDto request);
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
  Future<void> logout() async {
    return await api.logout();
  }

  @override
  Future<void> forgotPassword(ForgotPasswordRequestDto request) async {
    return await api.forgotPassword(request);
  }

  @override
  Future<void> resetPassword(ResetPasswordRequestDto request) async {
    return await api.resetPassword(request);
  }
}
