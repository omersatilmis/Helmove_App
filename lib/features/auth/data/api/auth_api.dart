import 'package:dio/dio.dart';
import 'auth_endpoints.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/social_sign_in_request_dto.dart';
import '../dto/register_request_dto.dart';
import '../dto/register_response_dto.dart';
import '../dto/forgot_password_request_dto.dart';
import '../dto/confirm_forgot_password_request_dto.dart';
import '../dto/reset_password_request_dto.dart';
import '../dto/refresh_token_request_dto.dart';
import '../dto/revoke_token_request_dto.dart';
import '../dto/session_dto.dart';
import '../../../../core/utils/app_logger.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      AppLogger.info("======== LOGIN START ========");
      AppLogger.debug("Request Data: ${request.toJson()}");

      final response = await _dio.post(
        AuthEndpoints.login,
        data: request.toJson(),
      );

      AppLogger.info("Response Status: ${response.statusCode}");
      AppLogger.debug("Response Data: ${response.data}");
      AppLogger.info("======== LOGIN END ========");

      return LoginResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error("======== LOGIN ERROR ========");
      AppLogger.error("Status: ${e.response?.statusCode}");
      AppLogger.error("Data: ${e.response?.data}");
      AppLogger.error("Message: ${e.message}");
      AppLogger.error("======== LOGIN END ========");

      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Giriş işlemi başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error("======== LOGIN UNEXPECTED ERROR ========");
      AppLogger.error("Error: $e");
      AppLogger.error("======== LOGIN END ========");
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  Future<LoginResponseDto> socialSignIn(SocialSignInRequestDto request) async {
    DioException? notFoundError;
    final candidatePaths = <String>[
      AuthEndpoints.socialLogin,
      ...AuthEndpoints.socialLoginFallbacks,
    ];

    for (final path in candidatePaths) {
      try {
        final response = await _dio.post(path, data: request.toJson());
        return LoginResponseDto.fromJson(response.data);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          notFoundError = e;
          continue;
        }
        final errorMessage =
            _parseErrorMessage(e.response?.data) ??
            'Sosyal giriş başarısız: ${e.response?.statusCode}';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception("Beklenmedik bir hata oluştu: $e");
      }
    }

    final statusCode = notFoundError?.response?.statusCode;
    throw Exception('Sosyal giriş endpointi bulunamadı: $statusCode');
  }

  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.register,
        data: request.toJson(),
      );

      // 🔍 Debug: Backend'in döndürdüğü veriyi logla
      AppLogger.info("======== REGISTER DEBUG ========");
      AppLogger.debug("Register Response: ${response.data}");
      AppLogger.debug("Response Type: ${response.data.runtimeType}");
      AppLogger.info("================================");

      return RegisterResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      // 🔍 Debug: Hata durumunda response'u logla
      AppLogger.error("======== REGISTER DIO ERROR ========");
      AppLogger.error("Status Code: ${e.response?.statusCode}");
      AppLogger.error("Response Data: ${e.response?.data}");
      AppLogger.error("====================================");

      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Kayıt işlemi başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      // 🔍 Debug: Beklenmedik hataları logla
      AppLogger.error("======== REGISTER UNEXPECTED ERROR ========");
      AppLogger.error("Error: $e");
      AppLogger.error("===========================================");
      throw Exception("Beklenmedik bir hata oluştu: $e");
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

  /// Forgot password doğrulama - Token ile yeni şifre belirleme
  Future<void> confirmForgotPassword(
    ConfirmForgotPasswordRequestDto request,
  ) async {
    try {
      await _dio.post(
        AuthEndpoints.confirmForgotPassword,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Şifre sıfırlama onayı başarısız: ${e.response?.statusCode}';
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

  /// Token Yenileme
  Future<LoginResponseDto> refreshToken(RefreshTokenRequestDto request) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.refreshToken,
        data: request.toJson(),
      );
      return LoginResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Token yenileme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// Token İptal Etme
  Future<void> revokeToken(RevokeTokenRequestDto request) async {
    try {
      await _dio.post(AuthEndpoints.revokeToken, data: request.toJson());
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Token iptal etme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// Aktif Oturumları Listeleme
  Future<List<SessionDto>> getSessions() async {
    try {
      final response = await _dio.get(AuthEndpoints.sessions);
      final data = response.data;

      if (data is Map && data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => SessionDto.fromJson(e))
            .toList();
      }
      // Eğer direkt liste dönüyorsa (bazı API'ler böyle yapabilir)
      if (data is List) {
        return data.map((e) => SessionDto.fromJson(e)).toList();
      }

      return [];
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Oturumları getirme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  /// Mevcut kullanıcı bilgilerini ve token'ını yeniler
  Future<LoginResponseDto> refreshCurrentUser() async {
    try {
      final response = await _dio.post(AuthEndpoints.refreshCurrentUser);
      return LoginResponseDto.fromJson(response.data);
    } on DioException catch (e) {
      final errorMessage =
          _parseErrorMessage(e.response?.data) ??
          'Kullanıcı yenileme başarısız: ${e.response?.statusCode}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("Beklenmedik bir hata oluştu: $e");
    }
  }

  // Logout güncellendi: İsteğe bağlı body alabilir
  Future<void> logout({RevokeTokenRequestDto? request}) async {
    try {
      await _dio.post(AuthEndpoints.logout, data: request?.toJson());
    } catch (e) {
      AppLogger.warning("Logout hatası: $e");
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
