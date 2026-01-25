import 'package:dio/dio.dart';
import 'auth_endpoints.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/register_response_dto.dart';
import '../dto/forgot_password_request_dto.dart';
import '../dto/reset_password_request_dto.dart';
import '../../../../core/utils/app_logger.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.login,
        data: request.toJson(),
      );
      return LoginResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Giriş işlemi başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.register,
        data: request.toJson(),
      );

      // 🔍 Debug: Backend'in döndürdüğü veriyi logla
      print("======== REGISTER DEBUG ========");
      print("Register Response: ${response.data}");
      print("Response Type: ${response.data.runtimeType}");
      print("================================");

      return RegisterResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      // 🔍 Debug: Hata durumunda response'u logla
      print("======== REGISTER DIO ERROR ========");
      print("Status Code: ${e.response?.statusCode}");
      print("Response Data: ${e.response?.data}");
      print("====================================");

      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Kayıt işlemi başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      // 🔍 Debug: Beklenmedik hataları logla
      print("======== REGISTER UNEXPECTED ERROR ========");
      print("Error: $e");
      print("===========================================");
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(AuthEndpoints.logout);
    } catch (e) {
      AppLogger.warning("Logout hatası: $e");
    }
  }

  /// Şifremi unuttum - Email'e sıfırlama linki gönderir
  Future<void> forgotPassword(ForgotPasswordRequestDto request) async {
    try {
      await _dio.post(AuthEndpoints.forgotPassword, data: request.toJson());
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Şifre sıfırlama isteği başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// Şifre sıfırlama - Mevcut şifre ile yeni şifre belirleme
  Future<void> resetPassword(ResetPasswordRequestDto request) async {
    try {
      await _dio.post(AuthEndpoints.resetPassword, data: request.toJson());
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Şifre değiştirme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// Hata mesajını response body'den güvenli bir şekilde çıkarır
  String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return data['message'] ??
          data['detail'] ??
          data['error'] ??
          data['description'];
    }

    if (data is String) {
      return data;
    }

    if (data is List) {
      // Eğer liste ise (örn: validasyon hataları), ilk elemanı string olarak döndür
      if (data.isNotEmpty) {
        final firstItem = data.first;
        if (firstItem is Map) {
          return firstItem['description'] ??
              firstItem['message'] ??
              firstItem['error'] ??
              firstItem.toString();
        }
        return firstItem.toString();
      }
    }

    return data.toString();
  }
}
