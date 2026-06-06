import 'dart:io';
import 'package:dio/dio.dart';

class MediaApi {
  final Dio _dio;

  MediaApi(this._dio);

  // /api/Media/upload endpointine yükleme yapar
  Future<String> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      // API Endpoint'ini backend'e göre düzeltebiliriz.
      // Genelde: /api/Upload, /api/Media/upload vb.
      final response = await _dio.post(
        '/api/Media/upload',
        data: formData,
        options: Options(
          headers: {
            // 'Content-Type': 'multipart/form-data', // Dio bunu otomatik ayarlar
          },
        ),
      );

      // Response formatını kontrol etmemiz lazım.
      // { "data": "https://url...", "success": true } veya direkt string dönebilir.
      if (response.data is Map<String, dynamic>) {
        if (response.data['data'] != null) {
          return response.data['data'].toString();
        }
        return response.data['url'] ?? response.data.toString();
      }

      return response.data.toString();
    } catch (e) {
      throw Exception('Resim yüklenemedi: $e');
    }
  }

  // /api/Media/upload-audio endpointine yükleme yapar (sesli mesaj için)
  Future<String> uploadAudio(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        '/api/Media/upload-audio',
        data: formData,
      );

      if (response.data is Map<String, dynamic>) {
        if (response.data['data'] != null) {
          return response.data['data'].toString();
        }
        return response.data['url'] ?? response.data.toString();
      }
      return response.data.toString();
    } catch (e) {
      throw Exception('Ses dosyası yüklenemedi: $e');
    }
  }
}
