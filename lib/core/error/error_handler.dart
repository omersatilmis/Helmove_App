import 'package:dio/dio.dart';
import 'package:moto_comm_app_1/core/error/app_exceptions.dart';

class ErrorHandler {
  /// Hata mesajını döndürür (kullanıcıya gösterilebilir)
  static String getErrorMessage(Object error) {
    if (error is NetworkException) return error.message;
    if (error is ServerException) return error.message;
    if (error is ValidationException) return error.message;
    if (error is AuthException) return error.message;
    if (error is NotFoundException) return error.message;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Bağlantı zaman aşımına uğradı. İnternetini kontrol et.";

        case DioExceptionType.badResponse:
          final message = error.response?.data['message'];
          if (message != null) return message.toString();

          final statusCode = error.response?.statusCode;
          if (statusCode == 401)
            return "Oturum süresi doldu veya şifre yanlış.";
          if (statusCode == 404) return "İstenen kaynak bulunamadı.";
          if (statusCode == 500)
            return "Sunucu hatası. Daha sonra tekrar dene.";
          return "Bir şeyler ters gitti. Hata kodu: $statusCode";

        case DioExceptionType.connectionError:
          return "Sunucuya ulaşılamıyor. İnternet bağlantını kontrol et.";

        case DioExceptionType.cancel:
          return "İstek iptal edildi.";

        default:
          return "Bilinmeyen bir bağlantı hatası oluştu.";
      }
    }

    return error.toString().replaceAll("Exception: ", "");
  }

  /// API hatalarını typed exception'a çevirir
  static Never handleApiError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = error.response?.data['message']?.toString();

    switch (statusCode) {
      case 400:
      case 422:
        throw ValidationException(message ?? 'Geçersiz veri');
      case 401:
      case 403:
        throw AuthException(message ?? 'Yetkilendirme hatası');
      case 404:
        throw NotFoundException(message ?? 'Kaynak bulunamadı');
      case 500:
      case 502:
      case 503:
        throw ServerException(message ?? 'Sunucu hatası', statusCode);
      default:
        throw ServerException(message ?? 'Bilinmeyen hata', statusCode);
    }
  }
}
