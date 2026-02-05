abstract class AttendanceRepository {
  /// Grup turuna katılma isteği gönderir
  Future<void> joinGroupRide(int rideId, {String? joinMessage});

  /// Grup turundan ayrılır
  Future<void> leaveGroupRide(int rideId);

  /// Katılımcıyı onaylar (Organizatör)
  Future<void> approveParticipant(int rideId, int userId);

  /// Katılımcıyı reddeder (Organizatör)
  Future<void> rejectParticipant(int rideId, int userId);

  /// Grup turunun katılımcılarını getirir
  Future<List<dynamic>> getRideParticipants(int rideId);

  /// Kullanıcının katılım durumunu kontrol eder
  Future<dynamic> getParticipationStatus(int rideId);
}
