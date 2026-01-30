import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';

abstract class MediaRepository {
  Future<Either<Failure, String>> uploadImage(File file);
}
