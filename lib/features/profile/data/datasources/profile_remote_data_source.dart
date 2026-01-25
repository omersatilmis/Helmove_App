import '../api/profile_api.dart';
import '../dto/profile_response_dto.dart';
import '../dto/update_profile_request_dto.dart';
import '../dto/motorcycle_dto.dart';

/// Remote Data Source Interface
abstract class ProfileRemoteDataSource {
  Future<ProfileResponseDto> getMyProfile();
  Future<ProfileResponseDto> updateProfile(UpdateProfileRequestDto request);
  Future<ProfileResponseDto> getUserProfile(int userId);
  Future<ProfileResponseDto> updateProfilePicture(String imagePath);
  Future<void> updateLocation(UpdateLocationRequestDto request);
  Future<MotorcyclesResponseDto> getMotorcycles();
  Future<MotorcycleDto> addMotorcycle(MotorcycleDto motorcycle);
  Future<MotorcycleDto> updateMotorcycle(
    int motorcycleId,
    MotorcycleDto motorcycle,
  );
  Future<void> deleteMotorcycle(int motorcycleId);
  Future<void> setPrimaryMotorcycle(int motorcycleId);
  Future<void> setOnlineStatus(bool isOnline);
  Future<bool> isUserOnline(int userId);
}

/// Remote Data Source Implementation
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ProfileApi api;

  ProfileRemoteDataSourceImpl({required this.api});

  @override
  Future<ProfileResponseDto> getMyProfile() => api.getMyProfile();

  @override
  Future<ProfileResponseDto> updateProfile(UpdateProfileRequestDto request) =>
      api.updateProfile(request);

  @override
  Future<ProfileResponseDto> getUserProfile(int userId) =>
      api.getUserProfile(userId);

  @override
  Future<ProfileResponseDto> updateProfilePicture(String imagePath) =>
      api.updateProfilePicture(imagePath);

  @override
  Future<void> updateLocation(UpdateLocationRequestDto request) =>
      api.updateLocation(request);

  @override
  Future<MotorcyclesResponseDto> getMotorcycles() => api.getMotorcycles();

  @override
  Future<MotorcycleDto> addMotorcycle(MotorcycleDto motorcycle) =>
      api.addMotorcycle(motorcycle);

  @override
  Future<MotorcycleDto> updateMotorcycle(
    int motorcycleId,
    MotorcycleDto motorcycle,
  ) => api.updateMotorcycle(motorcycleId, motorcycle);

  @override
  Future<void> deleteMotorcycle(int motorcycleId) =>
      api.deleteMotorcycle(motorcycleId);

  @override
  Future<void> setPrimaryMotorcycle(int motorcycleId) =>
      api.setPrimaryMotorcycle(motorcycleId);

  @override
  Future<void> setOnlineStatus(bool isOnline) => api.setOnlineStatus(isOnline);

  @override
  Future<bool> isUserOnline(int userId) => api.isUserOnline(userId);
}
