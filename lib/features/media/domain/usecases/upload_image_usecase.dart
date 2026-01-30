import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../repositories/media_repository.dart';

class UploadImageUseCase implements UseCase<String, File> {
  final MediaRepository repository;

  UploadImageUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(File params) {
    return repository.uploadImage(params);
  }
}
