import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../data/api/media_api.dart';
import '../../domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaApi api;

  MediaRepositoryImpl(this.api);

  @override
  Future<Either<Failure, String>> uploadImage(File file) async {
    try {
      final url = await api.uploadImage(file);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
