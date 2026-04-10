import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../../core/error/failures.dart';
import '../../data/api/media_api.dart';
import '../../domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaApi api;

  MediaRepositoryImpl(this.api);

  @override
  Future<Either<Failure, String>> uploadImage(File file) async {
    try {
      // 1. Compress image before upload
      final compressedFile = await _compressFile(file);
      
      // 2. Upload compressed file
      final url = await api.uploadImage(compressedFile ?? file);
      
      // 3. Clean up temporary compressed file if created
      if (compressedFile != null && compressedFile.path != file.path) {
        await compressedFile.delete();
      }
      
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<File?> _compressFile(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path, 
        "${DateTime.now().millisecondsSinceEpoch}_compressed.jpg"
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // %70 kalite (boyut/kalite dengesi en iyisi)
        minWidth: 1024, // Max genişlik 1024px
        minHeight: 1024,
        format: CompressFormat.jpeg,
        keepExif: true,
      );

      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      return null; // Sıkıştırma başarısız olursa orijinali gönder
    }
  }
}
