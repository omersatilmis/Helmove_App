import 'package:dartz/dartz.dart';
import '../../../../core/error/app_exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_group_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    int page = 1,
  }) async {
    try {
      final dtos = await remoteDataSource.getNotifications(page);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<NotificationGroupEntity>>> getGroupedNotifications({
    int page = 1,
  }) async {
    try {
      final dtos = await remoteDataSource.getGroupedNotifications(page);
      return Right(dtos.map((d) => d.toEntity()).toList());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      return Right(await remoteDataSource.getUnreadCount());
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int id) async {
    try {
      await remoteDataSource.markAsRead(id);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await remoteDataSource.markAllAsRead();
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(int id) async {
    try {
      await remoteDataSource.deleteNotification(id);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markGroupAsRead({
    int? actorId,
    required int type,
  }) async {
    try {
      await remoteDataSource.markGroupAsRead(actorId: actorId, type: type);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup({
    int? actorId,
    required int type,
  }) async {
    try {
      await remoteDataSource.deleteGroup(actorId: actorId, type: type);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
