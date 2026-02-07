import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/participant_entity.dart';
import '../entities/participation_status_entity.dart';

abstract class AttendanceRepository {
  /// Grup turuna katılma isteği gönderir
  Future<Either<Failure, Unit>> joinGroupRide(
    int rideId, {
    String? joinMessage,
  });

  /// Grup turundan ayrılır
  Future<Either<Failure, Unit>> leaveGroupRide(int rideId);

  /// Katılımcıyı onaylar (Organizatör)
  Future<Either<Failure, Unit>> approveParticipant(int rideId, int userId);

  /// Katılımcıyı reddeder (Organizatör)
  Future<Either<Failure, Unit>> rejectParticipant(int rideId, int userId);

  /// Grup turunun katılımcılarını getirir
  Future<Either<Failure, List<ParticipantEntity>>> getRideParticipants(
    int rideId,
  );

  /// Kullanıcının katılım durumunu kontrol eder
  Future<Either<Failure, ParticipationStatusEntity>> getParticipationStatus(
    int rideId,
  );
}
