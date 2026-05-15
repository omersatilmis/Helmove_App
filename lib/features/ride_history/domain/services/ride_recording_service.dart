import '../entities/ride_entity.dart';

abstract class RideRecordingService {
  Stream<RidePoint> get pointStream;
  bool get isRecording;
  Future<void> start();
  Future<RideEntity?> stop();
  Future<RideEntity?> recoverIfNeeded();
  Future<void> discardRecovery();
}
