import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:helmove/core/utils/app_logger.dart';

/// ImageCompressor - Resimleri sıkıştırır
class ImageCompressor {
  /// Resmi sıkıştırır ve yeni dosya yolunu döndürür
  /// [imagePath]: Orijinal resim yolu
  /// [quality]: Sıkıştırma kalitesi (0-100), varsayılan 80
  /// [maxWidth]: Maksimum genişlik, varsayılan 1024
  static Future<String> compress({
    required String imagePath,
    int quality = 80,
    int maxWidth = 1024,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        AppLogger.warning("ImageCompressor: File not found: $imagePath");
        return imagePath;
      }

      // Dosya boyutunu kontrol et (1MB altındaysa sıkıştırma)
      final fileSize = await file.length();
      if (fileSize < 500 * 1024) {
        // 500KB altındaysa olduğu gibi döndür
        AppLogger.info(
          "ImageCompressor: File small enough, skipping compression",
        );
        return imagePath;
      }

      // Geçici dizin al
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Sıkıştır
      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
      );

      if (result != null) {
        final newSize = await result.length();
        AppLogger.info(
          "ImageCompressor: Compressed ${fileSize ~/ 1024}KB -> ${newSize ~/ 1024}KB",
        );
        return result.path;
      }

      return imagePath;
    } catch (e) {
      AppLogger.warning("ImageCompressor error: $e");
      return imagePath; // Hata durumunda orijinal dosyayı döndür
    }
  }
}
