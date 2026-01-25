class RegisterResponseDto {
  final bool success;
  final String? message;

  RegisterResponseDto({required this.success, this.message});

  /// Backend cevabını okuyoruz
  /// Backend başarılı kayıtta farklı, hatalı kayıtta farklı format dönebilir
  factory RegisterResponseDto.fromJson(dynamic json) {
    // Eğer gelen veri null veya boşsa başarılı kabul et
    if (json == null) {
      return RegisterResponseDto(success: true);
    }

    // Eğer Map ise normal parse et
    if (json is Map<String, dynamic>) {
      // Backend'in hata formatı: {"status": 400, "detail": "..."}
      // veya başarı formatı: {"success": true, "message": "..."}
      final hasError = json.containsKey('status') && json['status'] != 200;

      if (hasError) {
        return RegisterResponseDto(
          success: false,
          message:
              json['detail'] ??
              json['title'] ??
              json['message'] ??
              "Kayıt başarısız",
        );
      }

      return RegisterResponseDto(
        success: json['success'] ?? true,
        message: json['message'] ?? json['detail'],
      );
    }

    // Beklenmedik format - başarılı kabul et
    return RegisterResponseDto(success: true);
  }
}
