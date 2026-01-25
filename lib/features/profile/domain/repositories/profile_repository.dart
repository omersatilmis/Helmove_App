import '../entities/profile_entity.dart';
import '../entities/motorcycle_entity.dart';

/// Profile Repository Abstract Interface
abstract class ProfileRepository {
  /// Kullanıcının kendi profilini getirir
  Future<ProfileEntity> getMyProfile();

  /// Kullanıcının profilini günceller
  Future<ProfileEntity> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? phoneNumber,
    String? address,
    String? city,
    String? region,
    bool? shareLocation,
    bool? showProfileToOthers,
  });

  /// Başka bir kullanıcının profilini getirir
  Future<ProfileEntity> getUserProfile(int userId);

  /// Profil resmini günceller
  Future<String> updateProfilePicture(String imagePath);

  /// Konumu günceller
  Future<void> updateLocation(double latitude, double longitude);

  /// Motosikletleri getirir
  Future<List<MotorcycleEntity>> getMotorcycles();

  /// Yeni motosiklet ekler
  Future<MotorcycleEntity> addMotorcycle({
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    int? engineSize,
    String? description,
    bool isPrimary = false,
  });

  /// Motosikleti günceller
  Future<MotorcycleEntity> updateMotorcycle({
    required int motorcycleId,
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    int? engineSize,
    String? description,
    bool isPrimary = false,
  });

  /// Motosikleti siler
  Future<void> deleteMotorcycle(int motorcycleId);

  /// Ana motosikleti ayarlar
  Future<void> setPrimaryMotorcycle(int motorcycleId);

  /// Online durumunu değiştirir
  Future<void> setOnlineStatus(bool isOnline);

  /// Belirli bir kullanıcının online durumunu kontrol eder
  Future<bool> isUserOnline(int userId);
}
