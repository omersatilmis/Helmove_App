import 'package:dio/dio.dart';

class ErrorHandler {
  static String getErrorMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Bağlantı zaman aşımına uğradı. İnternetini kontrol et.";

        case DioExceptionType.badResponse:
          // Backend'den gelen 400, 401, 500 hataları buraya düşer
          // Backend'in gönderdiği mesajı yakalamaya çalışıyoruz
          final message = error.response?.data['message'];
          if (message != null) return message.toString();

          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return "Oturum süresi doldu veya şifre yanlış.";
          }
          if (statusCode == 500) {
            return "Sunucu hatası. Daha sonra tekrar dene.";
          }
          return "Bir şeyler ters gitti. Hata kodu: $statusCode";

        case DioExceptionType.connectionError:
          return "Sunucuya ulaşılamıyor. İnternet bağlantını kontrol et.";

        case DioExceptionType.cancel:
          return "İstek iptal edildi.";

        default:
          return "Bilinmeyen bir bağlantı hatası oluştu.";
      }
    } else {
      // Dio dışındaki hatalar (Örn: Null pointer vs.)
      return error.toString().replaceAll("Exception: ", "");
    }
  }
}
