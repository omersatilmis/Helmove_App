import 'package:flutter/foundation.dart';
import 'package:moto_comm_app_1/features/profile/domain/entities/profile_entity.dart';
import 'package:moto_comm_app_1/features/profile/domain/entities/motorcycle_entity.dart';
import 'package:moto_comm_app_1/features/profile/domain/repositories/profile_repository.dart';
import 'package:moto_comm_app_1/core/utils/app_logger.dart';

/// ProfileProvider - Profil verilerini yönetir
class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  ProfileProvider(this._profileRepository);

  // State
  bool _isLoading = false;
  String? _errorMessage;
  ProfileEntity? _profile;
  ProfileEntity? _visitedProfile; // Başkasının profili
  List<MotorcycleEntity> _motorcycles = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProfileEntity? get profile => _profile;
  ProfileEntity? get visitedProfile => _visitedProfile;
  List<MotorcycleEntity> get motorcycles => _motorcycles;

  // Helper getters (Sadece kendi profilim için)
  String get firstName => _profile?.firstName ?? '';
  String get lastName => _profile?.lastName ?? '';
  String get username => _profile?.username ?? 'Kullanıcı';
  String get email => _profile?.email ?? '';
  String get fullName => _profile?.fullName ?? username;
  String? get profileImageUrl => _profile?.profileImageUrl;
  String? get bio => _profile?.bio;
  String? get phoneNumber => _profile?.phoneNumber;
  String? get city => _profile?.city;
  String? get region => _profile?.region;
  bool get isLoggedIn => _profile != null;

  /// Kendi profilimi yükler
  Future<void> loadProfile() async {
    _setLoading(true);
    clearError();

    try {
      _profile = await _profileRepository.getMyProfile();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Başkasının profilini yükler
  Future<void> loadUserProfile(int userId) async {
    _setLoading(true);
    clearError();
    _visitedProfile = null; // Önce temizle

    try {
      final response = await _profileRepository.getUserProfile(userId);
      _visitedProfile = response;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Profili günceller
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    String? phoneNumber,
    String? address,
    String? city,
    String? region,
    bool? shareLocation,
    bool? showProfileToOthers,
  }) async {
    _setLoading(true);
    clearError();

    try {
      _profile = await _profileRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        region: region,
        shareLocation: shareLocation,
        showProfileToOthers: showProfileToOthers,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Profil resmini günceller
  Future<bool> updateProfilePicture(String imagePath) async {
    _setLoading(true);
    clearError();

    try {
      await _profileRepository.updateProfilePicture(imagePath);
      await loadProfile(); // Profili yenile
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Konumu günceller
  Future<bool> updateLocation(double latitude, double longitude) async {
    try {
      await _profileRepository.updateLocation(latitude, longitude);
      return true;
    } catch (e) {
      AppLogger.warning("Konum güncelleme hatası: $e");
      return false;
    }
  }

  /// Motosikletleri yükler
  Future<void> loadMotorcycles() async {
    _setLoading(true);
    clearError();

    try {
      _motorcycles = await _profileRepository.getMotorcycles();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Motosiklet ekler
  Future<bool> addMotorcycle({
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    int? engineSize,
    String? description,
    bool isPrimary = false,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final motorcycle = await _profileRepository.addMotorcycle(
        brand: brand,
        model: model,
        year: year,
        licensePlate: licensePlate,
        color: color,
        engineSize: engineSize,
        description: description,
        isPrimary: isPrimary,
      );
      _motorcycles.add(motorcycle);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Motosikleti siler
  Future<bool> deleteMotorcycle(int motorcycleId) async {
    _setLoading(true);
    clearError();

    try {
      await _profileRepository.deleteMotorcycle(motorcycleId);
      _motorcycles.removeWhere((m) => m.id == motorcycleId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Ana motosikleti ayarlar
  Future<bool> setPrimaryMotorcycle(int motorcycleId) async {
    try {
      await _profileRepository.setPrimaryMotorcycle(motorcycleId);
      await loadMotorcycles(); // Listeyi yenile
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Profili temizler (logout)
  void clearProfile() {
    _profile = null;
    _motorcycles = [];
    notifyListeners();
  }

  // Yardımcı metodlar
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message.replaceAll("Exception: ", "");
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
