import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/jot_entity.dart';
import '../../domain/repositories/jots_repository.dart';
import '../datasources/jots_remote_datasource.dart';
import '../dto/jot_dto.dart';

class JotsRepositoryImpl implements JotsRepository {
  final JotsRemoteDataSource remoteDataSource;

  JotsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, JotEntity>> createJot({
    required JotType type,
    String? text,
    String? mediaUrl,
    String? thumbnailUrl,
    required JotVisibility visibility,
  }) async {
    try {
      final request = CreateJotRequest.fromEntity(
        type: type,
        text: text,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        visibility: visibility,
      );
      final result = await remoteDataSource.createJot(request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<JotEntity>>> getFeed({int page = 1}) async {
    try {
      final result = await remoteDataSource.getFeed(page: page);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<JotEntity>>> getUserJots(
    int userId, {
    int page = 1,
  }) async {
    try {
      final result = await remoteDataSource.getUserJots(userId, page: page);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteJot(int id) async {
    try {
      await remoteDataSource.deleteJot(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> likeJot(int id) async {
    try {
      await remoteDataSource.likeJot(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
