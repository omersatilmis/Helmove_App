import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/motorcycle_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../dto/update_profile_request_dto.dart';
import '../dto/motorcycle_dto.dart';
import '../mapper/profile_mapper.dart';
import '../../../../core/error/error_handler.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileEntity> getMyProfile() async {
    try {
      final response = await _remoteDataSource.getMyProfile();
      if (!response.success || response.data == null) {
        throw Exception(response.message ?? "Profil getirilemedi");
      }
      return ProfileMapper.toProfileEntity(response.data!);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<ProfileEntity> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? phoneNumber,
    String? address,
    String? city,
    String? region,
    bool? shareLocation,
    bool? showProfileToOthers,
    String? instagramUrl,
    String? youtubeUrl,
    String? twitterUrl,
  }) async {
    try {
      final request = UpdateProfileRequestDto(
        username: username,
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        region: region,
        shareLocation: shareLocation,
        showProfileToOthers: showProfileToOthers,
        instagramUrl: instagramUrl,
        youtubeUrl: youtubeUrl,
        twitterUrl: twitterUrl,
      );
      final response = await _remoteDataSource.updateProfile(request);
      if (!response.success || response.data == null) {
        throw Exception(response.message ?? "Profil güncellenemedi");
      }
      return ProfileMapper.toProfileEntity(response.data!);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<ProfileEntity> getUserProfile(int userId) async {
    try {
      final response = await _remoteDataSource.getUserProfile(userId);
      if (!response.success || response.data == null) {
        throw Exception(response.message ?? "Kullanıcı profili getirilemedi");
      }
      return ProfileMapper.toProfileEntity(response.data!);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<String> updateProfilePicture(String imagePath) async {
    try {
      final response = await _remoteDataSource.updateProfilePicture(imagePath);
      if (!response.success || response.data == null) {
        throw Exception(response.message ?? "Profil resmi güncellenemedi");
      }
      return response.data!.profileImageUrl ?? '';
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<String> updateCoverPhoto(String imagePath) async {
    try {
      final url = await _remoteDataSource.updateCoverPhoto(imagePath);
      return url;
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final request = UpdateLocationRequestDto(
        latitude: latitude,
        longitude: longitude,
      );
      await _remoteDataSource.updateLocation(request);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<List<MotorcycleEntity>> getMotorcycles() async {
    try {
      final response = await _remoteDataSource.getMotorcycles();
      if (!response.success || response.data == null) {
        throw Exception(response.message ?? "Motosikletler getirilemedi");
      }
      return ProfileMapper.toMotorcycleEntityList(response.data!);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<MotorcycleEntity> addMotorcycle({
    required String brand,
    required String model,
    int? year,
    String? licensePlate,
    String? color,
    int? engineSize,
    String? description,
    bool isPrimary = false,
  }) async {
    try {
      final dto = MotorcycleDto(
        brand: brand,
        model: model,
        year: year,
        licensePlate: licensePlate,
        color: color,
        engineSize: engineSize,
        description: description,
        isPrimary: isPrimary,
      );
      final result = await _remoteDataSource.addMotorcycle(dto);
      return ProfileMapper.toMotorcycleEntity(result);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
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
  }) async {
    try {
      final dto = MotorcycleDto(
        brand: brand,
        model: model,
        year: year,
        licensePlate: licensePlate,
        color: color,
        engineSize: engineSize,
        description: description,
        isPrimary: isPrimary,
      );
      final result = await _remoteDataSource.updateMotorcycle(
        motorcycleId,
        dto,
      );
      return ProfileMapper.toMotorcycleEntity(result);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> deleteMotorcycle(int motorcycleId) async {
    try {
      await _remoteDataSource.deleteMotorcycle(motorcycleId);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> setPrimaryMotorcycle(int motorcycleId) async {
    try {
      await _remoteDataSource.setPrimaryMotorcycle(motorcycleId);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      await _remoteDataSource.setOnlineStatus(isOnline);
    } catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Future<bool> isUserOnline(int userId) async {
    return await _remoteDataSource.isUserOnline(userId);
  }
}
