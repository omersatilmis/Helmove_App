import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/group_ride_entity.dart';
import '../../domain/entities/group_ride_participant_entity.dart';
import '../../domain/repositories/group_ride_repository.dart';
import '../datasources/group_ride_data_source.dart';

/// GroupRide Repository implementasyonu
class GroupRideRepositoryImpl implements GroupRideRepository {
  final GroupRideDataSource _dataSource;

  GroupRideRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, GroupRideEntity>> createGroupRide(
    Map<String, dynamic> data,
  ) async {
    try {
      final model = await _dataSource.createGroupRide(data);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupRideEntity>> getGroupRideById(int id) async {
    try {
      final model = await _dataSource.getGroupRideById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupRideEntity>>> getActiveGroupRides() async {
    try {
      final models = await _dataSource.getActiveGroupRides();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupRideEntity>>> getMyRides() async {
    try {
      final models = await _dataSource.getMyRides();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupRideEntity>>> getNearbyGroupRides(
    double latitude,
    double longitude, {
    double radiusKm = 50,
  }) async {
    try {
      final models = await _dataSource.getNearbyGroupRides(
        latitude,
        longitude,
        radiusKm: radiusKm,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinGroupRide(
    int rideId, {
    String? joinMessage,
  }) async {
    try {
      await _dataSource.joinGroupRide(rideId, joinMessage: joinMessage);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroupRide(int rideId) async {
    try {
      await _dataSource.leaveGroupRide(rideId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupRideParticipantEntity>>> getParticipants(
    int rideId,
  ) async {
    try {
      final models = await _dataSource.getParticipants(rideId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startGroupRide(int rideId) async {
    try {
      await _dataSource.startGroupRide(rideId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeGroupRide(int rideId) async {
    try {
      await _dataSource.completeGroupRide(rideId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroupRide(int rideId) async {
    try {
      await _dataSource.deleteGroupRide(rideId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
