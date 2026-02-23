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
          final data = error.response?.data;

          if (data != null) {
            // 1. Önce yaygın hata alanlarını kontrol et
            if (data is Map<String, dynamic>) {
              if (data.containsKey('message') && data['message'] != null) {
                return data['message'].toString();
              }
              if (data.containsKey('error') && data['error'] != null) {
                return data['error'].toString();
              }
              if (data.containsKey('detail') && data['detail'] != null) {
                return data['detail'].toString();
              }
              if (data.containsKey('errors')) {
                // 'errors' genellikle validasyon hatalarını içerir
                final errors = data['errors'];
                if (errors is Map) {
                  // Map ise her bir hatayı birleştir
                  return errors.entries
                      .map((e) => "${e.key}: ${e.value}")
                      .join("\n");
                } else if (errors is List) {
                  return errors.join("\n");
                }
                return errors.toString();
              }

              // Eğer hiçbiri yoksa ve data boş değilse, datayı string olarak göster
              // Bu, "null" hatası yerine ham veriyi görmemizi sağlar
              if (data.isNotEmpty) {
                return data.toString();
              }
            } else if (data is String) {
              return data;
            }
          }

          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return "Oturum süresi doldu veya şifre yanlış.";
          }
          if (statusCode == 404) return "İstenen kaynak bulunamadı.";
          if (statusCode == 500) {
            return "Sunucu hatası. Daha sonra tekrar dene.";
          }

          // Eğer data null ise ve status code varsa
          return "Bir şeyler ters gitti. Hata kodu: $statusCode\nDetay: ${error.message}";

        case DioExceptionType.connectionError:
          return "Sunucuya ulaşılamıyor. İnternet bağlantını kontrol et.";

        case DioExceptionType.cancel:
          return "İstek iptal edildi.";

        default:
          return "Bağlantı hatası: ${error.message ?? error.type.name}";
      }
    }

    // Exception: prefix'ini temizle ve string döndür
    return error.toString().replaceAll("Exception: ", "");
  }

  /// API hatalarını typed exception'a çevirir
  static Never handleApiError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = error.response?.data['message']?.toString();

    switch (statusCode) {
      case 400:
      case 422:
        throw ValidationException(
          message ?? 'Geçersiz veri girişi ($statusCode)',
        );
      case 401:
      case 403:
        throw AuthException(message ?? 'Yetkilendirme hatası ($statusCode)');
      case 404:
        throw NotFoundException(message ?? 'Kaynak bulunamadı ($statusCode)');
      case 500:
      case 502:
      case 503:
        throw ServerException(
          message ?? 'Sunucu hatası ($statusCode)',
          statusCode,
        );
      default:
        throw ServerException(
          message ?? 'Beklenmeyen hata ($statusCode)',
          statusCode,
        );
    }
  }
}
