// Typed Application Exceptions

/// Ağ bağlantısı hatası
class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'İnternet bağlantısı yok']);

  @override
  String toString() => message;
}

/// Sunucu hatası (5xx)
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException([this.message = 'Sunucu hatası', this.statusCode]);

  @override
  String toString() => message;
}

/// Doğrulama hatası (400, 422)
class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  ValidationException([this.message = 'Geçersiz veri', this.errors]);

  @override
  String toString() => message;
}

/// Yetkilendirme hatası (401, 403)
class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Oturum süresi doldu']);

  @override
  String toString() => message;
}

/// Kaynak bulunamadı (404)
class NotFoundException implements Exception {
  final String message;
  NotFoundException([this.message = 'İstenen kaynak bulunamadı']);

  @override
  String toString() => message;
}
